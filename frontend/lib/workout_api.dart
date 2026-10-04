import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.focus,
    required this.durationSeconds,
    required this.level,
  });

  final String id;
  final String name;
  final String focus;
  final int durationSeconds;
  final String level;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        focus: json['focus'] as String,
        durationSeconds: json['durationSeconds'] as int,
        level: json['level'] as String,
      );
}

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.completedAt,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final DateTime completedAt;

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String,
        title: json['title'] as String,
        durationMinutes: json['durationMinutes'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}

abstract interface class WorkoutService {
  Future<List<Exercise>> fetchExercises();
  Future<List<WorkoutRecord>> fetchWorkouts();
  Future<WorkoutRecord> createWorkout({
    required String title,
    required int durationMinutes,
  });
}

class WorkoutApi implements WorkoutService {
  WorkoutApi({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _baseUri = baseUri ?? _defaultBaseUri;

  final http.Client _client;
  final Uri _baseUri;

  static Uri get _defaultBaseUri {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return Uri.parse(configuredUrl);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:3000/api');
    }
    return Uri.parse('http://localhost:3000/api');
  }

  @override
  Future<List<Exercise>> fetchExercises() async {
    final response = await _client.get(_endpoint('exercises'));
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkoutRecord>> fetchWorkouts() async {
    final response = await _client.get(_endpoint('workouts'));
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => WorkoutRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutRecord> createWorkout({
    required String title,
    required int durationMinutes,
  }) async {
    final response = await _client.post(
      _endpoint('workouts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'durationMinutes': durationMinutes}),
    );
    _ensureSuccess(response);
    return WorkoutRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Uri _endpoint(String resource) => _baseUri.replace(
        path: '${_baseUri.path.replaceFirst(RegExp(r'/$'), '')}/$resource',
      );

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend returned ${response.statusCode}');
    }
  }
}