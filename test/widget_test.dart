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
import 'package:home_workout_frontend/home_workout_app.dart';
import 'package:home_workout_frontend/progress_screen.dart';
import 'package:home_workout_frontend/workout_api.dart';

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
      MaterialApp(home: WorkoutProgressScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ความก้าวหน้า'), findsOneWidget);
    expect(find.text('สรุปผลรายสัปดาห์ในช่วง 8 สัปดาห์ล่าสุด'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-progress-chart')), findsOneWidget);
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

  testWidgets('recovery day appears on calendar without starting a workout', (
    tester,
  ) async {
    final service = _FakeWorkoutService(
      currentDay: 4,
      hasRecoveryRestDay: true,
    );
    await tester.pumpWidget(HomeWorkoutApp(service: service));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123!');
    await tester.tap(find.text('เข้าสู่ระบบ'));
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
    await tester.pumpWidget(HomeWorkoutApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับกลับ'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123!');
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('พื้นที่เล็ก ๆ\nเพื่อร่างกายที่ดีขึ้น'), findsOneWidget);
    expect(find.text('เลือกพื้นที่ฝึก'), findsOneWidget);
    expect(find.text('ชาเลนจ์ 4 สัปดาห์'), findsOneWidget);
    expect(find.text('ท่าที่ฝึก'), findsNothing);
    expect(
      find.byKey(const ValueKey('profile-body-silhouette')),
      findsOneWidget,
    );

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

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> logout() async {}

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
    totalCalories: _workouts.fold(
      0,
      (total, workout) => total + workout.caloriesBurned,
    ),
    totalMinutes: _workouts.fold(
      0,
      (total, workout) => total + workout.durationMinutes,
    ),
  );

  @override
  Future<UserProfile> fetchProfile() async => profile;

  @override
  Future<UserProfile> updateProfile({
    required String? gender,
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) async {
    profile = UserProfile(
      email: profile.email,
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
    );
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
}
