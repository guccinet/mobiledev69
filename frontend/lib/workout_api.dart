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
    required this.sets,
    required this.repetitions,
    required this.unit,
  });

  final String id;
  final String name;
  final String focus;
  final int durationSeconds;
  final String level;
  final int sets;
  final int repetitions;
  final String unit;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    focus: json['focus'] as String,
    durationSeconds: json['durationSeconds'] as int,
    level: json['level'] as String,
    sets: json['sets'] as int,
    repetitions: json['repetitions'] as int,
    unit: json['unit'] as String,
  );

  String get prescription =>
      '$sets เซต × $repetitions ${unit == 'seconds' ? 'วินาที' : 'ครั้ง'}';
}

class WorkoutPlanDay {
  const WorkoutPlanDay({
    required this.dayNumber,
    required this.date,
    required this.title,
    required this.isCompleted,
    required this.isAvailable,
    required this.exercises,
    this.isRestDay = false,
  });

  final int dayNumber;
  final DateTime date;
  final String title;
  final bool isCompleted;
  final bool isAvailable;
  final bool isRestDay;
  final List<Exercise> exercises;

  factory WorkoutPlanDay.fromJson(Map<String, dynamic> json) => WorkoutPlanDay(
    dayNumber: json['dayNumber'] as int,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool,
    isAvailable: json['isAvailable'] as bool,
    isRestDay: json['isRestDay'] as bool? ?? false,
    exercises: (json['exercises'] as List<dynamic>)
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.focus,
    required this.focusLabel,
    required this.difficulty,
    required this.difficultyLabel,
    required this.currentDay,
    required this.days,
  });

  final String focus;
  final String focusLabel;
  final String difficulty;
  final String difficultyLabel;
  final int currentDay;
  final List<WorkoutPlanDay> days;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    focus: json['focus'] as String,
    focusLabel: json['focusLabel'] as String,
    difficulty: json['difficulty'] as String,
    difficultyLabel: json['difficultyLabel'] as String,
    currentDay: json['currentDay'] as int,
    days: (json['days'] as List<dynamic>)
        .map((day) => WorkoutPlanDay.fromJson(day as Map<String, dynamic>))
        .toList(),
  );
}

class WorkoutStats {
  const WorkoutStats({
    required this.completedDays,
    required this.totalExercises,
    required this.totalCalories,
    required this.totalMinutes,
  });

  final int completedDays;
  final int totalExercises;
  final int? totalCalories;
  final int totalMinutes;

  factory WorkoutStats.fromJson(Map<String, dynamic> json) => WorkoutStats(
    completedDays: json['completedDays'] as int,
    totalExercises: json['totalExercises'] as int,
    totalCalories: json['totalCalories'] as int?,
    totalMinutes: json['totalMinutes'] as int,
  );
}

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.title,
    required this.focus,
    required this.dayNumber,
    required this.exerciseCount,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String focus;
  final int dayNumber;
  final int exerciseCount;
  final int? caloriesBurned;
  final int durationMinutes;
  final DateTime completedAt;

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
    id: json['id'].toString(),
    title: json['title'] as String,
    focus: json['focus'] as String,
    dayNumber: json['dayNumber'] as int,
    exerciseCount: json['exerciseCount'] as int,
    caloriesBurned: json['caloriesBurned'] as int?,
    durationMinutes: json['durationMinutes'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}

class UserProfile {
  const UserProfile({
    required this.email,
    this.gender,
    this.age,
    this.weightKg,
    this.heightCm,
  });

  final String email;
  final String? gender;
  final int? age;
  final double? weightKg;
  final double? heightCm;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    email: json['email'] as String,
    gender: json['gender'] as String?,
    age: json['age'] as int?,
    weightKg: _nullableDouble(json['weightKg']),
    heightCm: _nullableDouble(json['heightCm']),
  );

  static double? _nullableDouble(Object? value) =>
      value == null ? null : double.parse(value.toString());
}

class WeightEntry {
  const WeightEntry({required this.id, required this.weightKg, required this.recordedAt});

  final int id;
  final double weightKg;
  final DateTime recordedAt;

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'] as int,
    weightKg: double.parse(json['weightKg'].toString()),
    recordedAt: DateTime.parse(json['recordedAt'] as String),
  );
}

abstract interface class WorkoutService {
  Future<WorkoutPlan> fetchPlan({
    required String focus,
    required String difficulty,
  });
  Future<List<WorkoutRecord>> fetchWorkouts();
  Future<WorkoutStats> fetchStats();
  Future<UserProfile> fetchProfile();
  Future<List<WeightEntry>> fetchWeightHistory();
  Future<WeightEntry> recordWeight({required double weightKg});
  Future<UserProfile> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  });
  Future<WorkoutRecord> createWorkout({
    required String focus,
    required String difficulty,
    required int dayNumber,
    required int durationMinutes,
  });
  Future<WorkoutRecord> updateWorkout({
    required String id,
    required int durationMinutes,
  });
  Future<void> deleteWorkout({required String id});
}

class WorkoutApi implements WorkoutService {
  WorkoutApi({
    required this.accessTokenProvider,
    http.Client? client,
    Uri? baseUri,
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? _defaultBaseUri;

  final http.Client _client;
  final Uri _baseUri;
  final Future<String?> Function() accessTokenProvider;

  static Uri get _defaultBaseUri {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return Uri.parse(configuredUrl);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:3000/api');
    }
    return Uri.parse('http://localhost:3000/api');
  }

  @override
  Future<WorkoutPlan> fetchPlan({
    required String focus,
    required String difficulty,
  }) async {
    final response = await _client.get(
      _endpoint('plan')
          .replace(queryParameters: {'focus': focus, 'difficulty': difficulty}),
      headers: await _headers,
    );
    _ensureSuccess(response);
    return WorkoutPlan.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<WorkoutRecord>> fetchWorkouts() async {
    final response = await _client.get(
      _endpoint('workouts'),
      headers: await _headers,
    );
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => WorkoutRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutStats> fetchStats() async {
    final response = await _client.get(
      _endpoint('stats'),
      headers: await _headers,
    );
    _ensureSuccess(response);
    return WorkoutStats.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<UserProfile> fetchProfile() async {
    final response = await _client.get(
      _endpoint('profile'),
      headers: await _headers,
    );
    _ensureSuccess(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<WeightEntry>> fetchWeightHistory() async {
    final response = await _client.get(
      _endpoint('weights'),
      headers: await _headers,
    );
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => WeightEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WeightEntry> recordWeight({required double weightKg}) async {
    final response = await _client.post(
      _endpoint('weights'),
      headers: await _headers,
      body: jsonEncode({'weightKg': weightKg}),
    );
    _ensureSuccess(response);
    return WeightEntry.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<UserProfile> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) async {
    final response = await _client.patch(
      _endpoint('profile'),
      headers: await _headers,
      body: jsonEncode({
        'gender': gender,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
      }),
    );
    _ensureSuccess(response);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WorkoutRecord> createWorkout({
    required String focus,
    required String difficulty,
    required int dayNumber,
    required int durationMinutes,
  }) async {
    final response = await _client.post(
      _endpoint('workouts'),
      headers: await _headers,
      body: jsonEncode({
        'focus': focus,
        'difficulty': difficulty,
        'dayNumber': dayNumber,
        'durationMinutes': durationMinutes,
      }),
    );
    _ensureSuccess(response);
    return WorkoutRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WorkoutRecord> updateWorkout({
    required String id,
    required int durationMinutes,
  }) async {
    final response = await _client.patch(
      _endpoint('workouts/$id'),
      headers: await _headers,
      body: jsonEncode({'durationMinutes': durationMinutes}),
    );
    _ensureSuccess(response);
    return WorkoutRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteWorkout({required String id}) async {
    final response = await _client.delete(
      _endpoint('workouts/$id'),
      headers: await _headers,
    );
    _ensureSuccess(response);
  }

  Uri _endpoint(String resource) => _baseUri.replace(
    path: '${_baseUri.path.replaceFirst(RegExp(r'/$'), '')}/$resource',
  );

  Future<Map<String, String>> get _headers async {
    final accessToken = await accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('ไม่พบ access token กรุณาเข้าสู่ระบบใหม่');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Backend returned ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final detail =
              body['detail'] ??
              (body.values.isEmpty ? null : body.values.first);
          if (detail is String) {
            message = detail;
          } else if (detail is List<dynamic> && detail.isNotEmpty) {
            message = detail.first.toString();
          } else if (detail != null) {
            message = detail.toString();
          }
        }
      } on FormatException {
        // Retain the HTTP status message for non-JSON error responses.
      }
      throw Exception(message);
    }
  }
}
