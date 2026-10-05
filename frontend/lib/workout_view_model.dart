import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'data_result.dart';
import 'workout_api.dart';
import 'workout_repository.dart';

class WorkoutViewModel {
  const WorkoutViewModel(this._repository);

  final WorkoutRepository _repository;

  Future<T> _unwrap<T>(Future<DataResult<T>> result) async =>
      (await result).fold(
        onSuccess: (value) => value,
        onFailure: (error, stackTrace) => Error.throwWithStackTrace(
          error,
          stackTrace ?? StackTrace.current,
        ),
      );

  Future<WorkoutPlan> fetchPlan({
    required String focus,
    required String difficulty,
  }) => _unwrap(
    _repository.fetchPlan(focus: focus, difficulty: difficulty),
  );

  Future<List<WorkoutRecord>> fetchWorkouts() =>
      _unwrap(_repository.fetchWorkouts());

  Future<WorkoutStats> fetchStats() => _unwrap(_repository.fetchStats());

  Future<UserProfile> fetchProfile() => _unwrap(_repository.fetchProfile());

  Future<UserProfile> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) => _unwrap(
    _repository.updateProfile(
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
    ),
  );

  Future<WorkoutRecord> createWorkout({
    required String focus,
    required String difficulty,
    required int dayNumber,
    required int durationMinutes,
  }) => _unwrap(
    _repository.createWorkout(
      focus: focus,
      difficulty: difficulty,
      dayNumber: dayNumber,
      durationMinutes: durationMinutes,
    ),
  );

  Future<WorkoutRecord> updateWorkout({
    required String id,
    required int durationMinutes,
  }) => _unwrap(
    _repository.updateWorkout(id: id, durationMinutes: durationMinutes),
  );

  Future<void> deleteWorkout({required String id}) =>
      _unwrap(_repository.deleteWorkout(id: id));
}

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _initialized = false;
  Object? _error;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Object? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    _notify();
    final result = await _repository.initialize();
    result.fold(
      onSuccess: (authenticated) {
        _initialized = true;
        _isAuthenticated = authenticated;
        _error = null;
      },
      onFailure: (error, _) {
        _initialized = false;
        _error = error;
      },
    );
    _isLoading = false;
    _notify();
  }

  Future<void> signIn() async {
    if (!_initialized) {
      await initialize();
      if (!_initialized) return;
    }
    _isLoading = true;
    _error = null;
    _notify();
    final result = await _repository.signIn();
    result.fold(
      onSuccess: (_) => _isAuthenticated = _repository.isAuthenticated,
      onFailure: (error, _) => _error = error,
    );
    _isLoading = false;
    _notify();
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    _notify();
    final result = await _repository.signOut();
    result.fold(
      onSuccess: (_) => _isAuthenticated = _repository.isAuthenticated,
      onFailure: (error, _) => _error = error,
    );
    _isLoading = false;
    _notify();
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}