import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, before, test } from 'node:test';

import { createServer } from '../src/server.js';

let directory;
let server;
let baseUrl;

before(async () => {
  directory = await mkdtemp(join(tmpdir(), 'home-workout-'));
  server = createServer({ dataFile: join(directory, 'workouts.json') });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await rm(directory, { recursive: true, force: true });
});

test('serves exercise list and records workout history', async () => {
  const exerciseResponse = await fetch(`${baseUrl}/api/exercises`);
  assert.equal(exerciseResponse.status, 200);
  assert.equal((await exerciseResponse.json()).length, 6);

  const createResponse = await fetch(`${baseUrl}/api/workouts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'โปรแกรมทั้งตัว', durationMinutes: 12 }),
  });
  assert.equal(createResponse.status, 201);
  const created = await createResponse.json();
  assert.equal(created.title, 'โปรแกรมทั้งตัว');
  assert.equal(created.durationMinutes, 12);

  const historyResponse = await fetch(`${baseUrl}/api/workouts`);
  assert.deepEqual(await historyResponse.json(), [created]);
  assert.match(await readFile(join(directory, 'workouts.json'), 'utf8'), /โปรแกรมทั้งตัว/);
});

test('rejects invalid workout durations', async () => {
  const response = await fetch(`${baseUrl}/api/workouts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'Invalid', durationMinutes: 0 }),
  });
  assert.equal(response.status, 400);
});