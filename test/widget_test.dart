// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workout_frontend/exercise_guide.dart';
import 'package:home_workout_frontend/exercise_illustration.dart';
import 'package:home_workout_frontend/home_screen.dart';
import 'package:home_workout_frontend/home_workout_app.dart';
import 'package:home_workout_frontend/oidc_auth_service.dart';
import 'package:home_workout_frontend/progress_screen.dart';
import 'package:home_workout_frontend/workout_api.dart';
import 'package:home_workout_frontend/workout_repository.dart';
import 'package:home_workout_frontend/workout_view_model.dart';

void main() {
  test('workout plan identifies recovery days returned by the API', () {
    final day = WorkoutPlanDay.fromJson({
      'dayNumber': 4,
      'date': '2026-10-08',
      'title': 'วันพักฟื้นหลังฝึกต่อเนื่อง',
      'isCompleted': false,
      'isAvailable': true,
      'isRestDay': true,
      'exercises': [],
    });

    expect(day.isRestDay, isTrue);
    expect(day.title, 'วันพักฟื้นหลังฝึกต่อเนื่อง');
  });

  test('difficulty recommendation uses age and recent workout history', () {
    final now = DateTime(2026, 10, 5);
    final profile = UserProfile(
      email: 'athlete@example.com',
      age: 28,
      gender: 'female',
      weightKg: 62.5,
    );

    expect(
      recommendWorkoutDifficulty(profile, const [], now: now).level,
      'เริ่มฝึก',
    );

    final consistentWorkouts = List.generate(
      8,
      (index) => WorkoutRecord(
        id: '$index',
        title: 'Workout $index',
        focus: 'abs',
        dayNumber: index + 1,
        exerciseCount: 4,
        caloriesBurned: 50,
        durationMinutes: 20,
        completedAt: now.subtract(Duration(days: index * 3)),
      ),
    );
    expect(
      recommendWorkoutDifficulty(profile, consistentWorkouts, now: now).level,
      'ปานกลาง',
    );
    expect(
      recommendWorkoutDifficulty(
        profile,
        consistentWorkouts,
        now: now,
      ).recentWorkouts,
      8,
    );
    expect(
      recommendWorkoutDifficulty(
        UserProfile(
          email: 'athlete@example.com',
          age: 28,
          gender: 'male',
          weightKg: 140,
        ),
        consistentWorkouts,
        now: now,
      ).level,
      'ปานกลาง',
    );
    expect(
      recommendWorkoutDifficulty(
        UserProfile(email: 'athlete@example.com', age: 16),
        consistentWorkouts,
        now: now,
      ).level,
      'เริ่มฝึก',
    );
    expect(
      recommendWorkoutDifficulty(
        UserProfile(email: 'athlete@example.com'),
        consistentWorkouts,
        now: now,
      ).level,
      'เริ่มฝึก',
    );
  });

  testWidgets('progress screen displays selectable weekly chart and guidance', (
    tester,
  ) async {
    final service = _FakeWorkoutService();
    service.profile = const UserProfile(email: 'test@example.com', age: 30);
    service._workouts.add(
      WorkoutRecord(
        id: 'recent',
        title: 'หน้าท้อง · วันที่ 1',
        focus: 'abs',
        dayNumber: 1,
        exerciseCount: 4,
        caloriesBurned: 50,
        durationMinutes: 10,
        completedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutProgressScreen(
          service: WorkoutViewModel(WorkoutRepository(service)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ความก้าวหน้า'), findsOneWidget);
    expect(find.text('สรุปผลรายสัปดาห์ในช่วง 8 สัปดาห์ล่าสุด'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-progress-chart')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ระดับที่แนะนำ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ระดับที่แนะนำ'), findsOneWidget);
    expect(
      find.textContaining('เพศและน้ำหนักไม่ได้ใช้ตัดสินระดับโดยตรง'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('progress-metric-minutes')));
    await tester.pumpAndSettle();
    expect(find.text('เวลาออกกำลังกาย'), findsOneWidget);
    expect(find.text('10 นาทีใน 8 สัปดาห์'), findsOneWidget);
  });

  test('weekly weight reminder is due after seven calendar days', () {
    final now = DateTime(2026, 10, 6, 9);
    expect(isWeightUpdateDue(const [], now: now), isTrue);
    expect(
      isWeightUpdateDue([
        WeightEntry(id: 1, weightKg: 65, recordedAt: DateTime(2026, 9, 30, 18)),
      ], now: now),
      isFalse,
    );
    expect(
      isWeightUpdateDue([
        WeightEntry(id: 1, weightKg: 65, recordedAt: DateTime(2026, 9, 29, 18)),
      ], now: now),
      isTrue,
    );
  });

  testWidgets('progress screen logs weight and renders its history chart', (
    tester,
  ) async {
    final service = _FakeWorkoutService();
    service.weightHistory.addAll([
      WeightEntry(
        id: 1,
        weightKg: 70,
        recordedAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      WeightEntry(
        id: 2,
        weightKg: 69.5,
        recordedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutProgressScreen(
          service: WorkoutViewModel(WorkoutRepository(service)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weight-history-chart')), findsOneWidget);
    expect(find.text('ติดตามน้ำหนัก'), findsOneWidget);
    expect(find.textContaining('เปลี่ยนแปลง -0.5 กก.'), findsOneWidget);
    expect(find.text('ถึงเวลาอัปเดตน้ำหนักประจำสัปดาห์แล้ว'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('weight-entry-input')),
      '69',
    );
    await tester.tap(find.byKey(const ValueKey('record-weight-button')));
    await tester.pumpAndSettle();

    expect(service.weightHistory.last.weightKg, 69);
    expect(service.profile.weightKg, 69);
    expect(find.text('บันทึกน้ำหนักเรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('ถึงเวลาอัปเดตน้ำหนักประจำสัปดาห์แล้ว'), findsNothing);
  });

  testWidgets('workout history supports detail, update, and delete', (
    tester,
  ) async {
    final service = _FakeWorkoutService();
    service._workouts.add(
      WorkoutRecord(
        id: 'history-1',
        title: 'หน้าท้อง · วันที่ 1',
        focus: 'abs',
        dayNumber: 1,
        exerciseCount: 4,
        caloriesBurned: 50,
        durationMinutes: 10,
        completedAt: DateTime(2026, 10, 5),
      ),
    );
    final viewModel = WorkoutViewModel(WorkoutRepository(service));

    await tester.pumpWidget(
      MaterialApp(home: WorkoutHistoryScreen(service: viewModel)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('หน้าท้อง · วันที่ 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('จำนวนท่า: 4'), findsOneWidget);
    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('จัดการรายการ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(service._workouts.single.durationMinutes, 12);

    await tester.tap(find.byTooltip('จัดการรายการ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 250));
    expect(service._workouts, isEmpty);
    expect(find.text('หน้าท้อง · วันที่ 1'), findsNothing);
  });

  testWidgets('recovery day appears on calendar without starting a workout', (
    tester,
  ) async {
    final service = _FakeWorkoutService(
      currentDay: 4,
      hasRecoveryRestDay: true,
    );
    await tester.pumpWidget(
      HomeWorkoutApp(service: service, authService: _FakeOidcAuthService()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าสู่ระบบผ่าน OIDC'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('วันที่ 4 · วันพักฟื้น'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('พัก'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('challenge-day-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('วันพักฟื้นหลังฝึกต่อเนื่อง'), findsOneWidget);
    expect(find.text('เวลาฝึกของวันนี้'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('rest-day-return')));
    await tester.pumpAndSettle();
    expect(service.createdWorkout, isFalse);
  });

  test('every exercise in the workout catalog has form guidance', () {
    const exerciseIds = [
      'crunches',
      'bicycle-crunch',
      'leg-raises',
      'plank',
      'mountain-climbers',
      'dead-bug',
      'push-ups',
      'wide-push-ups',
      'incline-push-ups',
      'diamond-push-ups',
      'shoulder-taps',
      'knee-push-ups',
      'triceps-dips',
      'pike-push-ups',
      'arm-circles',
      'plank-up-downs',
      'close-grip-push-ups',
      'wall-push-ups',
      'squats',
      'reverse-lunges',
      'glute-bridges',
      'calf-raises',
      'wall-sit',
      'sumo-squats',
      'superman',
      'reverse-snow-angels',
      'bird-dog',
      'cobra-stretch',
      'swimmers',
      'pike-hold',
      'recovery-stretch',
    ];

    for (final id in exerciseIds) {
      final guide = guideForExercise(id);
      expect(guide.steps, isNotEmpty, reason: id);
      expect(guide.tip, isNotEmpty, reason: id);
    }
    expect(
      guideForExercise('incline-push-ups').motion,
      ExerciseMotion.inclinePushUp,
    );
    expect(
      guideForExercise('diamond-push-ups').motion,
      ExerciseMotion.diamondPushUp,
    );
  });

  testWidgets('all exercise illustrations paint without errors', (
    tester,
  ) async {
    for (final motion in ExerciseMotion.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ExerciseIllustration(
                motion: motion,
                label: 'ตัวอย่างท่าออกกำลังกาย',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: motion.name);
    }
  });

  testWidgets('signs in, opens a challenge day, and saves the workout', (
    tester,
  ) async {
    final service = _FakeWorkoutService(timedExerciseDuration: 2);
    service.profile = const UserProfile(
      email: 'test@example.com',
      age: 28,
      weightKg: 62.5,
      heightCm: 168,
    );
    await tester.pumpWidget(
      HomeWorkoutApp(service: service, authService: _FakeOidcAuthService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับกลับ'), findsOneWidget);
    await tester.tap(find.text('เข้าสู่ระบบผ่าน OIDC'));
    await tester.pumpAndSettle();

    expect(find.text('พื้นที่เล็ก ๆ\nเพื่อร่างกายที่ดีขึ้น'), findsOneWidget);
    expect(find.text('เลือกพื้นที่ฝึก'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-total-exercises')), findsOneWidget);
    expect(find.text('ท่าที่ฝึก'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-total-calories')), findsOneWidget);
    expect(find.text('แคลอรีรวม'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-total-minutes')), findsOneWidget);
    expect(find.text('นาทีฝึก'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ชาเลนจ์ 4 สัปดาห์'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ชาเลนจ์ 4 สัปดาห์'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-total-exercises')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-body-silhouette')),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('โปรไฟล์'));
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('profile-age')), '28');
    await tester.enterText(
      find.byKey(const ValueKey('profile-weight')),
      '62.5',
    );
    await tester.enterText(find.byKey(const ValueKey('profile-height')), '168');
    await tester.tap(find.byKey(const ValueKey('profile-gender')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('หญิง').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-profile')));
    await tester.pumpAndSettle();
    expect(find.text('บันทึกโปรไฟล์เรียบร้อยแล้ว'), findsOneWidget);
    expect(service.profile.gender, 'female');
    expect(service.profile.age, 28);
    expect(service.profile.weightKg, 62.5);
    expect(service.profile.heightCm, 168);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ความก้าวหน้า'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weekly-progress-chart')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ระดับที่แนะนำ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ระดับที่แนะนำ'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('challenge-day-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('challenge-day-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Crunches'), findsOneWidget);
    expect(find.text('ภาพสาธิตท่าฝึก'), findsOneWidget);
    expect(find.text('ลูกศรแสดงทิศทาง'), findsOneWidget);
    expect(find.text('วิธีทำ'), findsOneWidget);
    expect(find.text('เวลาฝึกของวันนี้'), findsOneWidget);
    expect(find.text('ท่านี้เสร็จแล้ว · ถัดไป'), findsOneWidget);
    expect(find.text('ประวัติการฝึก'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();
    expect(find.text('Exercise 1'), findsOneWidget);
    expect(find.text('00:02'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('exercise-next')))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('ครบเวลาแล้ว'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();
    expect(find.text('Exercise 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();
    expect(find.text('Exercise 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.createdWorkout, isTrue);
    expect(find.text('หน้าท้อง · วันที่ 1'), findsOneWidget);
    expect(find.text('ประวัติการฝึก'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ประวัติการฝึก'));
    await tester.pumpAndSettle();
    expect(find.text('ประวัติการฝึก'), findsOneWidget);
    expect(find.text('หน้าท้อง · วันที่ 1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('challenge-day-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('challenge-day-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('เวลาฝึกของวันนี้'), findsNothing);
    expect(find.text('00:02'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('exercise-next')));
    await tester.pump();
    expect(find.text('เป้าหมาย: 3 เซต × 2 วินาที'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('เป้าหมาย: 3 เซต × 2 วินาที'), findsOneWidget);
  });
}

class _FakeWorkoutService implements WorkoutService {
  _FakeWorkoutService({
    this.timedExerciseDuration = 30,
    this.currentDay = 1,
    this.hasRecoveryRestDay = false,
  });

  final int timedExerciseDuration;
  final int currentDay;
  final bool hasRecoveryRestDay;
  UserProfile profile = const UserProfile(email: 'test@example.com');
  bool createdWorkout = false;
  final List<WorkoutRecord> _workouts = [];
  final List<WeightEntry> weightHistory = [];

  @override
  Future<WorkoutPlan> fetchPlan({
    required String focus,
    required String difficulty,
  }) async {
    final exercises = List.generate(
      4,
      (index) => Exercise(
        id: 'exercise-$index',
        name: index == 0 ? 'Crunches' : 'Exercise $index',
        focus: 'หน้าท้อง',
        durationSeconds: index == 1 ? timedExerciseDuration : 30,
        level: 'เริ่มฝึก',
        sets: 3,
        repetitions: index == 1 ? timedExerciseDuration : 15,
        unit: index == 1 ? 'seconds' : 'reps',
      ),
    );
    return WorkoutPlan(
      focus: focus,
      focusLabel: 'หน้าท้อง',
      difficulty: difficulty,
      difficultyLabel: 'เริ่มฝึก',
      currentDay: currentDay,
      days: List.generate(28, (index) {
        final dayNumber = index + 1;
        final isRestDay =
            dayNumber == 7 || (hasRecoveryRestDay && dayNumber == 4);
        return WorkoutPlanDay(
          dayNumber: dayNumber,
          date: DateTime.utc(2026, 1, dayNumber),
          title: isRestDay
              ? 'วันพักฟื้นหลังฝึกต่อเนื่อง'
              : 'หน้าท้อง · วันที่ $dayNumber',
          isCompleted: _workouts.any(
            (workout) => workout.dayNumber == dayNumber,
          ),
          isAvailable: dayNumber <= currentDay,
          isRestDay: isRestDay,
          exercises: isRestDay
              ? const [
                  Exercise(
                    id: 'recovery-stretch',
                    name: 'Recovery Stretch',
                    focus: 'ยืดเหยียดฟื้นฟู',
                    durationSeconds: 300,
                    level: 'ทุกระดับ',
                    sets: 1,
                    repetitions: 300,
                    unit: 'seconds',
                  ),
                ]
              : exercises,
        );
      }),
    );
  }

  @override
  Future<List<WorkoutRecord>> fetchWorkouts() async => _workouts;

  @override
  Future<WorkoutStats> fetchStats() async => WorkoutStats(
    completedDays: _workouts.length,
    totalExercises: _workouts.fold(
      0,
      (total, workout) => total + workout.exerciseCount,
    ),
    totalCalories: _workouts.fold<int>(
      0,
      (total, workout) => total + (workout.caloriesBurned ?? 0),
    ),
    totalMinutes: _workouts.fold(
      0,
      (total, workout) => total + workout.durationMinutes,
    ),
  );

  @override
  Future<UserProfile> fetchProfile() async => profile;

  @override
  Future<List<WeightEntry>> fetchWeightHistory() async => weightHistory;

  @override
  Future<WeightEntry> recordWeight({required double weightKg}) async {
    profile = UserProfile(
      email: profile.email,
      gender: profile.gender,
      age: profile.age,
      weightKg: weightKg,
      heightCm: profile.heightCm,
    );
    final entry = WeightEntry(
      id: weightHistory.length + 1,
      weightKg: weightKg,
      recordedAt: DateTime.now(),
    );
    weightHistory.add(entry);
    return entry;
  }

  @override
  Future<UserProfile> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) async {
    final weightChanged = weightKg != profile.weightKg;
    profile = UserProfile(
      email: profile.email,
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
    );
    if (weightChanged && weightKg != null) {
      await recordWeight(weightKg: weightKg);
    }
    return profile;
  }

  @override
  Future<WorkoutRecord> createWorkout({
    required String focus,
    required String difficulty,
    required int dayNumber,
    required int durationMinutes,
  }) async {
    createdWorkout = true;
    final workout = WorkoutRecord(
      id: '1',
      title: 'หน้าท้อง · วันที่ $dayNumber',
      focus: focus,
      dayNumber: dayNumber,
      exerciseCount: 4,
      caloriesBurned: 50,
      durationMinutes: durationMinutes,
      completedAt: DateTime.now(),
    );
    _workouts.add(workout);
    return workout;
  }

  @override
  Future<WorkoutRecord> updateWorkout({
    required String id,
    required int durationMinutes,
  }) async {
    final index = _workouts.indexWhere((workout) => workout.id == id);
    if (index < 0) throw StateError('Workout not found');
    final old = _workouts[index];
    final updated = WorkoutRecord(
      id: old.id,
      title: old.title,
      focus: old.focus,
      dayNumber: old.dayNumber,
      exerciseCount: old.exerciseCount,
      caloriesBurned: durationMinutes * 5,
      durationMinutes: durationMinutes,
      completedAt: old.completedAt,
    );
    _workouts[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteWorkout({required String id}) async {
    _workouts.removeWhere((workout) => workout.id == id);
  }
}

class _FakeOidcAuthService extends OidcAuthService {
  bool _authenticated = false;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signIn() async => _authenticated = true;

  @override
  Future<void> signOut() async => _authenticated = false;

  @override
  Future<String?> getAccessToken() async =>
      _authenticated ? 'test-token' : null;
}
