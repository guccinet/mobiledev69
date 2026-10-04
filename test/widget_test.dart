// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workout_frontend/home_workout_app.dart';
import 'package:home_workout_frontend/workout_api.dart';

void main() {
  testWidgets('shows exercises and saves a workout through the service',
      (tester) async {
    final service = _FakeWorkoutService();
    await tester.pumpWidget(HomeWorkoutApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('พื้นที่เล็ก ๆ\nเพื่อร่างกายที่ดีขึ้น'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('ประวัติการฝึก'), findsOneWidget);

    await tester.tap(find.text('เริ่มบันทึกการฝึก'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ประวัติการฝึก'));
    await tester.scrollUntilVisible(
      find.text('โปรแกรมทั้งตัว'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(service.createdWorkout, isTrue);
    expect(find.text('โปรแกรมทั้งตัว'), findsOneWidget);
    expect(find.text('บันทึกการออกกำลังกายแล้ว'), findsOneWidget);
  });
}

class _FakeWorkoutService implements WorkoutService {
  bool createdWorkout = false;

  @override
  Future<List<Exercise>> fetchExercises() async => const [
        Exercise(
          id: 'squat',
          name: 'Squat',
          focus: 'ขาและสะโพก',
          durationSeconds: 40,
          level: 'เริ่มต้น',
        ),
      ];

  @override
  Future<List<WorkoutRecord>> fetchWorkouts() async => const [];

  @override
  Future<WorkoutRecord> createWorkout({
    required String title,
    required int durationMinutes,
  }) async {
    createdWorkout = true;
    return WorkoutRecord(
      id: 'record-1',
      title: title,
      durationMinutes: durationMinutes,
      completedAt: DateTime.utc(2026),
    );
  }
}
