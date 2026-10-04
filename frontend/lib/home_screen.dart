import 'package:flutter/material.dart';

import 'workout_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});

  final WorkoutService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _loadTask;
  List<Exercise> _exercises = const [];
  List<WorkoutRecord> _workouts = const [];
  Object? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTask = _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.service.fetchExercises(),
        widget.service.fetchWorkouts(),
      ]);
      _exercises = results[0] as List<Exercise>;
      _workouts = results[1] as List<WorkoutRecord>;
      _loadError = null;
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> _refresh() async {
    setState(() => _loadTask = _load());
    await _loadTask;
    if (mounted) setState(() {});
  }

  Future<void> _startWorkout() async {
    setState(() => _saving = true);
    try {
      final record = await widget.service.createWorkout(
        title: 'โปรแกรมทั้งตัว',
        durationMinutes: 12,
      );
      if (!mounted) return;
      setState(() {
        _workouts = [record, ..._workouts];
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการออกกำลังกายแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อ backend ไม่สำเร็จ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadTask,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_loadError != null) return _ConnectionError(onRetry: _refresh);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                    sliver: SliverList.list(
                      children: [
                        _TopBar(),
                        const SizedBox(height: 30),
                        const Text(
                          'พื้นที่เล็ก ๆ\nเพื่อร่างกายที่ดีขึ้น',
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF192A23),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _TodayWorkoutCard(
                          onStart: _saving ? null : _startWorkout,
                          saving: _saving,
                        ),
                        const SizedBox(height: 30),
                        _SectionHeading(
                          title: 'ท่าฝึกวันนี้',
                          trailing: '${_exercises.length} ท่า',
                        ),
                        const SizedBox(height: 12),
                        ..._exercises.map((exercise) => _ExerciseRow(
                              exercise: exercise,
                            )),
                        const SizedBox(height: 28),
                        _SectionHeading(
                          title: 'ประวัติการฝึก',
                          trailing: '${_workouts.length} ครั้ง',
                        ),
                        const SizedBox(height: 12),
                        if (_workouts.isEmpty)
                          const _EmptyHistory()
                        else
                          ..._workouts.take(3).map(_WorkoutRow.new),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF192A23),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, color: Color(0xFFB7D36B), size: 23),
        ),
        const SizedBox(width: 10),
        const Text(
          'MOVE DAILY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: Color(0xFF192A23),
          ),
        ),
        const Spacer(),
        Text(
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Color(0xFF66736C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({required this.onStart, required this.saving});

  final VoidCallback? onStart;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF192A23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFFB7D36B)),
              const SizedBox(width: 8),
              Text(
                'โปรแกรมแนะนำ  /  ระดับเริ่มต้น',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'FULL BODY\nRESET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.02,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFFB7D36B), size: 17),
              SizedBox(width: 6),
              Text('12 นาที', style: TextStyle(color: Colors.white)),
              SizedBox(width: 18),
              Icon(Icons.fitness_center, color: Color(0xFFB7D36B), size: 17),
              SizedBox(width: 6),
              Text('6 ท่า', style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(saving ? 'กำลังบันทึก...' : 'เริ่มบันทึกการฝึก'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB7D36B),
                foregroundColor: const Color(0xFF192A23),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF192A23),
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF66736C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE1E0D7))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E9D8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFF455E45),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${exercise.focus}  ·  ${exercise.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF66736C),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${exercise.durationSeconds} วิ',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF66736C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow(this.workout);

  final WorkoutRecord workout;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF658344), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                workout.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${workout.durationMinutes} นาที',
              style: const TextStyle(color: Color(0xFF66736C)),
            ),
          ],
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'ยังไม่มีประวัติการฝึก เริ่มครั้งแรกได้เลย',
          style: TextStyle(color: Color(0xFF66736C)),
        ),
      );
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 42, color: Color(0xFFE66A3D)),
              const SizedBox(height: 14),
              const Text(
                'ยังเชื่อมต่อ backend ไม่ได้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'ตรวจว่าเปิด API server แล้วลองอีกครั้ง',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
}