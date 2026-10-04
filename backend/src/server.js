import { randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { createServer as createHttpServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const backendDirectory = dirname(dirname(fileURLToPath(import.meta.url)));
const defaultDataFile = join(backendDirectory, 'data', 'workouts.json');

export const exercises = [
  { id: 'squat', name: 'Squat', focus: 'ขาและสะโพก', durationSeconds: 40, level: 'เริ่มต้น' },
  { id: 'push-up', name: 'Push-up', focus: 'อกและแขน', durationSeconds: 40, level: 'เริ่มต้น' },
  { id: 'lunge', name: 'Reverse lunge', focus: 'ขาและการทรงตัว', durationSeconds: 40, level: 'เริ่มต้น' },
  { id: 'plank', name: 'Plank', focus: 'แกนกลางลำตัว', durationSeconds: 30, level: 'เริ่มต้น' },
  { id: 'bridge', name: 'Glute bridge', focus: 'สะโพกและหลัง', durationSeconds: 40, level: 'เริ่มต้น' },
  { id: 'dead-bug', name: 'Dead bug', focus: 'แกนกลางลำตัว', durationSeconds: 40, level: 'เริ่มต้น' },
];

async function readWorkouts(dataFile) {
  try {
    return JSON.parse(await readFile(dataFile, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    throw error;
  }
}

function sendJson(response, statusCode, value) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(value));
}

async function readRequestBody(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 16_384) throw new Error('Request body too large');
  }
  return JSON.parse(body || '{}');
}

export function createServer({ dataFile = defaultDataFile } = {}) {
  return createHttpServer(async (request, response) => {
    response.setHeader('Access-Control-Allow-Origin', '*');
    response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method === 'OPTIONS') {
      response.writeHead(204);
      response.end();
      return;
    }

    const url = new URL(request.url, 'http://localhost');
    try {
      if (request.method === 'GET' && url.pathname === '/api/health') {
        sendJson(response, 200, { status: 'ok' });
        return;
      }
      if (request.method === 'GET' && url.pathname === '/api/exercises') {
        sendJson(response, 200, exercises);
        return;
      }
      if (request.method === 'GET' && url.pathname === '/api/workouts') {
        sendJson(response, 200, await readWorkouts(dataFile));
        return;
      }
      if (request.method === 'POST' && url.pathname === '/api/workouts') {
        const payload = await readRequestBody(request);
        const title = typeof payload.title === 'string' ? payload.title.trim() : '';
        const durationMinutes = Number(payload.durationMinutes);
        if (!title || !Number.isInteger(durationMinutes) || durationMinutes < 1 || durationMinutes > 300) {
          sendJson(response, 400, { error: 'title and durationMinutes (1-300) are required' });
          return;
        }

        const workout = {
          id: randomUUID(),
          title,
          durationMinutes,
          completedAt: new Date().toISOString(),
        };
        const workouts = await readWorkouts(dataFile);
        workouts.unshift(workout);
        await mkdir(dirname(dataFile), { recursive: true });
        await writeFile(dataFile, `${JSON.stringify(workouts, null, 2)}\n`);
        sendJson(response, 201, workout);
        return;
      }
      sendJson(response, 404, { error: 'Not found' });
    } catch (error) {
      const statusCode = error.message === 'Request body too large' ? 413 : 400;
      sendJson(response, statusCode, { error: statusCode === 413 ? error.message : 'Invalid request' });
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 3000);
  createServer().listen(port, '0.0.0.0', () => {
    console.log(`Workout API listening on http://localhost:${port}`);
  });
}