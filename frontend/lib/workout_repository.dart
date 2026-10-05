import 'data_result.dart';
import 'workout_api.dart';

class WorkoutRepository {
  const WorkoutRepository(this._service);

  final WorkoutService _service;

  Future<DataResult<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return DataSuccess(await operation());
    } on Exception catch (error, stackTrace) {
      return DataFailure(error, stackTrace);
    }
  }

  Future<DataResult<WorkoutPlan>> fetchPlan({
    required String focus,
    required String difficulty,
  }) => _run(
    () => _service.fetchPlan(focus: focus, difficulty: difficulty),
  );

  Future<DataResult<List<WorkoutRecord>>> fetchWorkouts() =>
      _run(_service.fetchWorkouts);

  Future<DataResult<WorkoutStats>> fetchStats() => _run(_service.fetchStats);

  Future<DataResult<UserProfile>> fetchProfile() =>
      _run(_service.fetchProfile);

  Future<DataResult<List<WeightEntry>>> fetchWeightHistory() =>
      _run(_service.fetchWeightHistory);

  Future<DataResult<WeightEntry>> recordWeight({
    required double weightKg,
  }) => _run(() => _service.recordWeight(weightKg: weightKg));

  Future<DataResult<UserProfile>> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) => _run(
    () => _service.updateProfile(
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
    ),
  );

  Future<DataResult<WorkoutRecord>> createWorkout({
    required String focus,
    required String difficulty,
    required int dayNumber,
    required int durationMinutes,
  }) => _run(
    () => _service.createWorkout(
      focus: focus,
      difficulty: difficulty,
      dayNumber: dayNumber,
      durationMinutes: durationMinutes,
    ),
  );

  Future<DataResult<WorkoutRecord>> updateWorkout({
    required String id,
    required int durationMinutes,
  }) => _run(
    () => _service.updateWorkout(id: id, durationMinutes: durationMinutes),
  );

  Future<DataResult<void>> deleteWorkout({required String id}) =>
      _run(() => _service.deleteWorkout(id: id));
}