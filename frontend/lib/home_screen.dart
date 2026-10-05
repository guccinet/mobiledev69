import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'exercise_guide.dart';
import 'exercise_illustration.dart';
import 'progress_screen.dart';
import 'workout_api.dart';
import 'workout_view_model.dart';

const _ink = Color(0xFF192A23);
const _muted = Color(0xFF66736C);
const _lime = Color(0xFFB7D36B);
const _orange = Color(0xFFE66A3D);

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onSignIn,
    required this.isLoading,
    this.error,
  });

  final Future<void> Function() onSignIn;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: _lime, size: 36),
                ),
                const SizedBox(height: 22),
                const Text(
                  'MOVE DAILY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ยินดีต้อนรับกลับ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'เข้าสู่ระบบด้วยบัญชีผู้ให้บริการเพื่อไปต่อกับเป้าหมายของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 30),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : onSignIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'เข้าสู่ระบบผ่าน OIDC',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service, required this.onSignOut});

  final WorkoutViewModel service;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _focusAreas = [
    ('abs', 'หน้าท้อง', Icons.self_improvement),
    ('chest', 'หน้าอก', Icons.fitness_center),
    ('arms', 'แขน', Icons.sports_gymnastics),
    ('legs', 'ขา', Icons.directions_walk),
    ('shoulder_back', 'ไหล่ & หลัง', Icons.accessibility_new),
  ];
  static const _levels = [
    ('beginner', 'เริ่มฝึก'),
    ('intermediate', 'ปานกลาง'),
    ('advanced', 'ขั้นสูง'),
  ];

  String _focus = 'abs';
  String _difficulty = 'beginner';
  int _loadGeneration = 0;
  late Future<void> _loadTask;
  WorkoutPlan? _plan;
  WorkoutStats _stats = const WorkoutStats(
    completedDays: 0,
    totalExercises: 0,
    totalCalories: 0,
    totalMinutes: 0,
  );
  UserProfile _profile = const UserProfile(email: '');
  List<WeightEntry> _weightHistory = const [];
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTask = _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final focus = _focus;
    final difficulty = _difficulty;
    try {
      final results = await Future.wait<Object>([
        widget.service.fetchPlan(focus: focus, difficulty: difficulty),
        widget.service.fetchStats(),
        widget.service.fetchProfile(),
        widget.service.fetchWeightHistory(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _plan = results[0] as WorkoutPlan;
        _stats = results[1] as WorkoutStats;
        _profile = results[2] as UserProfile;
        _weightHistory = results[3] as List<WeightEntry>;
        _loadError = null;
      });
    } catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loadError = error);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTask = _load();
    });
    await _loadTask;
  }

  Future<void> _setSelection({String? focus, String? difficulty}) async {
    setState(() {
      _focus = focus ?? _focus;
      _difficulty = difficulty ?? _difficulty;
      _plan = null;
      _loadError = null;
      _loadTask = _load();
    });
    await _loadTask;
  }

  Future<void> _openWorkout(WorkoutPlanDay day) async {
    if (!day.isAvailable && !day.isCompleted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          service: widget.service,
          day: day,
          focus: _focus,
          difficulty: _difficulty,
        ),
      ),
    );
    if (completed == true) await _refresh();
  }

  Future<void> _signOut() async {
    await widget.onSignOut();
    if (mounted) {
      final error = context.read<AuthViewModel>().error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<void>(
        future: _loadTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _plan == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_loadError != null && _plan == null) {
            return _ConnectionError(error: _loadError!, onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  sliver: SliverList.list(
                    children: [
                      _TopBar(
                        onOpenHistory: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutHistoryScreen(service: widget.service),
                          ),
                        ),
                        onOpenProfile: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfileScreen(service: widget.service),
                            ),
                          );
                          if (mounted) await _refresh();
                        },
                        onOpenProgress: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutProgressScreen(service: widget.service),
                          ),
                        ),
                        onSignOut: _signOut,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'พื้นที่เล็ก ๆ\nเพื่อร่างกายที่ดีขึ้น',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StatsCard(stats: _stats, profile: _profile),
                      if (isWeightUpdateDue(_weightHistory)) ...[
                        const SizedBox(height: 12),
                        _WeightReminderCard(
                          onUpdate: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => WorkoutProgressScreen(
                                service: widget.service,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const _SectionHeading(
                        title: 'เลือกพื้นที่ฝึก',
                        trailing: 'NO EQUIPMENT',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _focusAreas
                            .map(
                              (area) => ChoiceChip(
                                avatar: Icon(area.$3, size: 17),
                                label: Text(area.$2),
                                selected: _focus == area.$1,
                                onSelected: (_) =>
                                    _setSelection(focus: area.$1),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      const _SectionHeading(
                        title: 'ระดับความยาก',
                        trailing: 'เลือกให้เหมาะกับคุณ',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _levels
                            .map(
                              (level) => ChoiceChip(
                                label: Text(level.$2),
                                selected: _difficulty == level.$1,
                                onSelected: (_) =>
                                    _setSelection(difficulty: level.$1),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                      _SectionHeading(
                        title: 'ชาเลนจ์ 4 สัปดาห์',
                        trailing: _plan == null
                            ? ''
                            : 'วันที่ ${_plan!.currentDay} / 28',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_focusAreas.firstWhere((item) => item.$1 == _focus).$2} · '
                        '${_levels.firstWhere((item) => item.$1 == _difficulty).$2}',
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 14),
                      if (_plan case final plan?)
                        _ChallengeCalendar(plan: plan, onTapDay: _openWorkout)
                      else
                        const LinearProgressIndicator(),
                      const SizedBox(height: 28),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onOpenHistory,
    required this.onOpenProfile,
    required this.onOpenProgress,
    required this.onSignOut,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenProgress;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
          child: const Icon(Icons.bolt, color: _lime, size: 23),
        ),
        const SizedBox(width: 10),
        const Text(
          'MOVE DAILY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: _ink,
          ),
        ),
        const Spacer(),
        Text(
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}',
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        IconButton(
          tooltip: 'ประวัติการฝึก',
          onPressed: onOpenHistory,
          icon: const Icon(Icons.history, color: _ink),
        ),
        IconButton(
          tooltip: 'โปรไฟล์',
          onPressed: onOpenProfile,
          icon: const Icon(Icons.person_outline, color: _ink),
        ),
        IconButton(
          tooltip: 'ความก้าวหน้า',
          onPressed: onOpenProgress,
          icon: const Icon(Icons.insights_outlined, color: _ink),
        ),
        IconButton(
          tooltip: 'ออกจากระบบ',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, color: _ink),
        ),
      ],
    );
  }
}

class _WeightReminderCard extends StatelessWidget {
  const _WeightReminderCard({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('weight-update-reminder'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6E9D8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.monitor_weight_outlined, color: _ink),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ถึงเวลาอัปเดตน้ำหนักประจำสัปดาห์',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: onUpdate,
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.profile});

  final WorkoutStats stats;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _BodySilhouetteStat(profile: profile),
            _StatItem(
              value: stats.totalCalories?.toString() ?? '—',
              label: 'แคลอรี',
            ),
            _StatItem(value: '${stats.totalMinutes}', label: 'นาที'),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'แคลอรีประมาณด้วย MET · คิดเฉพาะรายการที่มีน้ำหนัก',
          style: TextStyle(color: Color(0xFFD5DCD7), fontSize: 11),
        ),
      ],
    ),
  );
}

class _BodySilhouetteStat extends StatelessWidget {
  const _BodySilhouetteStat({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: 'รูปร่างโดยประมาณจากส่วนสูงและน้ำหนักในโปรไฟล์',
      child: Tooltip(
        message: profile.heightCm == null || profile.weightKg == null
            ? 'เพิ่มน้ำหนักและส่วนสูงในโปรไฟล์เพื่อปรับภาพสัญลักษณ์'
            : 'ภาพสัญลักษณ์โดยประมาณจากข้อมูลโปรไฟล์ ไม่ใช่ภาพร่างกายจริง',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 62,
              child: CustomPaint(
                key: const ValueKey('profile-body-silhouette'),
                painter: _BodySilhouettePainter(
                  heightCm: profile.heightCm,
                  weightKg: profile.weightKg,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'รูปร่างโดยประมาณ',
              style: TextStyle(color: Color(0xFFD5DCD7), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BodySilhouettePainter extends CustomPainter {
  const _BodySilhouettePainter({
    required this.heightCm,
    required this.weightKg,
  });

  final double? heightCm;
  final double? weightKg;

  @override
  void paint(Canvas canvas, Size size) {
    final heightFactor = heightCm == null
        ? .9
        : (.78 + ((heightCm! - 140) / 70).clamp(0, 1) * .22).toDouble();
    final bmi = heightCm == null || weightKg == null || heightCm! <= 0
        ? 22.0
        : weightKg! / ((heightCm! / 100) * (heightCm! / 100));
    final widthFactor = (.78 + ((bmi - 16) / 24).clamp(0, 1) * .42);
    final figureHeight = size.height * heightFactor;
    final figureWidth = size.width * widthFactor;
    final centerX = size.width / 2;
    final top = (size.height - figureHeight) / 2;
    final fill = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = const Color(0xFFD5DCD7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;

    canvas.save();
    canvas.translate(centerX, top);
    canvas.scale(figureWidth / 48, figureHeight / 100);

    canvas.drawOval(const Rect.fromLTWH(-6, 0, 12, 15), fill);
    canvas.drawOval(const Rect.fromLTWH(-6, 0, 12, 15), outline);

    final torso = Path()
      ..moveTo(-5, 17)
      ..quadraticBezierTo(-12, 18, -15, 24)
      ..lineTo(-11, 43)
      ..lineTo(-9, 57)
      ..quadraticBezierTo(0, 61, 9, 57)
      ..lineTo(11, 43)
      ..lineTo(15, 24)
      ..quadraticBezierTo(12, 18, 5, 17)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, outline);

    final limbs = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final limbOutline = Paint()
      ..color = const Color(0xFFD5DCD7)
      ..strokeWidth = 5.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final side in const [-1.0, 1.0]) {
      final shoulder = Offset(side * 12, 22);
      final elbow = Offset(side * 17, 39);
      final wrist = Offset(side * 18, 53);
      final hip = Offset(side * 6, 56);
      final knee = Offset(side * 7, 76);
      final ankle = Offset(side * 8, 96);
      for (final points in [
        [shoulder, elbow],
        [elbow, wrist],
        [hip, knee],
        [knee, ankle],
      ]) {
        final path = Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy);
        canvas.drawPath(path, limbOutline);
        canvas.drawPath(path, limbs);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodySilhouettePainter oldDelegate) =>
      oldDelegate.heightCm != heightCm || oldDelegate.weightKg != weightKg;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD5DCD7), fontSize: 12),
        ),
      ],
    ),
  );
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
          color: _ink,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(
          fontSize: 12,
          color: _muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ChallengeCalendar extends StatelessWidget {
  const _ChallengeCalendar({required this.plan, required this.onTapDay});

  final WorkoutPlan plan;
  final ValueChanged<WorkoutPlanDay> onTapDay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tileWidth = (constraints.maxWidth - 36) / 7;
      return Wrap(
        spacing: 6,
        runSpacing: 8,
        children: plan.days.map((day) {
          final tileColor = day.isCompleted
              ? _lime
              : day.isRestDay
              ? const Color(0xFFDCE7E1)
              : day.dayNumber == plan.currentDay
              ? _ink
              : const Color(0xFFE9E8DF);
          return SizedBox(
            width: tileWidth,
            height: 50,
            child: InkWell(
              key: ValueKey('challenge-day-${day.dayNumber}'),
              borderRadius: BorderRadius.circular(8),
              onTap: day.isAvailable || day.isCompleted
                  ? () => onTapDay(day)
                  : null,
              child: Tooltip(
                message: day.isRestDay
                    ? 'วันที่ ${day.dayNumber} · วันพักฟื้น'
                    : 'วันที่ ${day.dayNumber}',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: day.isCompleted
                        ? const Icon(Icons.check, size: 18, color: _ink)
                        : day.isRestDay
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hotel_outlined,
                                size: 17,
                                color: day.isAvailable ? _ink : _muted,
                              ),
                              Text(
                                'พัก',
                                style: TextStyle(
                                  height: 1,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: day.isAvailable ? _ink : _muted,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${day.dayNumber}',
                            style: TextStyle(
                              color: day.dayNumber == plan.currentDay
                                  ? Colors.white
                                  : day.isAvailable
                                  ? _ink
                                  : const Color(0xFF9AA29C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.service,
    required this.day,
    required this.focus,
    required this.difficulty,
  });

  final WorkoutViewModel service;
  final WorkoutPlanDay day;
  final String focus;
  final String difficulty;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timerTicker;
  bool _saving = false;
  bool _timerRunning = false;
  Duration _elapsed = Duration.zero;
  int _exerciseIndex = 0;
  int _remainingSeconds = 0;

  Exercise get _exercise => widget.day.exercises[_exerciseIndex];

  bool get _isTimedExercise =>
      widget.day.exercises.isNotEmpty && _exercise.unit == 'seconds';

  bool get _isLastExercise =>
      widget.day.exercises.isEmpty ||
      _exerciseIndex == widget.day.exercises.length - 1;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _initialRemainingSeconds;
    if (!widget.day.isCompleted && !widget.day.isRestDay) {
      _stopwatch.start();
      _timerRunning = true;
    }
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted ||
          !_timerRunning ||
          widget.day.isCompleted ||
          widget.day.isRestDay) {
        return;
      }
      setState(() {
        _elapsed = _stopwatch.elapsed;
        if (_isTimedExercise && _remainingSeconds > 0) {
          _remainingSeconds--;
        }
      });
    });
  }

  int get _initialRemainingSeconds =>
      widget.day.exercises.isNotEmpty &&
          widget.day.exercises[_exerciseIndex].unit == 'seconds'
      ? widget.day.exercises[_exerciseIndex].durationSeconds
      : 0;

  @override
  void dispose() {
    _timerTicker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _toggleTimer() {
    if (widget.day.isCompleted || widget.day.isRestDay) return;
    setState(() {
      if (_timerRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
      _timerRunning = !_timerRunning;
    });
  }

  void _advanceExercise() {
    if (widget.day.isRestDay) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.day.isCompleted) {
      if (_isLastExercise) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _exerciseIndex++;
          _remainingSeconds = _initialRemainingSeconds;
        });
      }
      return;
    }
    if (_isLastExercise) {
      _finishWorkout();
      return;
    }
    setState(() {
      _exerciseIndex++;
      _remainingSeconds = _initialRemainingSeconds;
    });
  }

  Future<void> _finishWorkout() async {
    setState(() => _saving = true);
    final minutes = (_stopwatch.elapsed.inSeconds / 60)
        .ceil()
        .clamp(1, 300)
        .toInt();
    try {
      await widget.service.createWorkout(
        focus: widget.focus,
        difficulty: widget.difficulty,
        dayNumber: widget.day.dayNumber,
        durationMinutes: minutes,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกการฝึกไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedMinutes = (widget.day.exercises.length * 2.5).round();
    final exerciseCount = widget.day.exercises.length;
    return Scaffold(
      appBar: AppBar(title: Text('วันที่ ${widget.day.dayNumber}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: exerciseCount == 0
                  ? const Center(child: Text('วันนี้ยังไม่มีท่าฝึก'))
                  : ListView(
                      key: const ValueKey('exercise-detail-list'),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      children: [
                        Text(
                          widget.day.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.difficulty.toUpperCase()}  ·  ประมาณ $estimatedMinutes นาที',
                          style: const TextStyle(color: _muted),
                        ),
                        const SizedBox(height: 18),
                        _ExerciseProgress(
                          current: _exerciseIndex + 1,
                          total: exerciseCount,
                        ),
                        const SizedBox(height: 16),
                        if (!widget.day.isCompleted &&
                            !widget.day.isRestDay) ...[
                          _WorkoutTimer(
                            elapsed: _elapsed,
                            isRunning: _timerRunning,
                            onToggle: _toggleTimer,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_isTimedExercise &&
                            !widget.day.isCompleted &&
                            !widget.day.isRestDay)
                          _ExerciseCountdown(
                            remainingSeconds: _remainingSeconds,
                          )
                        else
                          _ExerciseInstruction(
                            exercise: _exercise,
                            isCompleted: widget.day.isCompleted,
                          ),
                        const SizedBox(height: 12),
                        _ExerciseCard(
                          exercise: _exercise,
                          number: _exerciseIndex + 1,
                        ),
                        if (widget.day.isRestDay)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'วันนี้เป็นวันพักฟื้น ไม่ต้องบันทึกการฝึก',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF658344),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else if (widget.day.isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'วันนี้ฝึกสำเร็จแล้ว · โหมดดูท่าฝึก',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF658344),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: ValueKey(
                    widget.day.isRestDay
                        ? 'rest-day-return'
                        : _isLastExercise
                        ? 'finish-workout'
                        : 'exercise-next',
                  ),
                  onPressed:
                      _saving ||
                          (!_isLastExercise &&
                              !widget.day.isCompleted &&
                              !widget.day.isRestDay &&
                              _isTimedExercise &&
                              _remainingSeconds > 0)
                      ? null
                      : _advanceExercise,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          widget.day.isRestDay
                              ? Icons.arrow_back
                              : widget.day.isCompleted
                              ? _isLastExercise
                                    ? Icons.close
                                    : Icons.arrow_forward
                              : _isLastExercise
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward,
                        ),
                  label: Text(
                    widget.day.isCompleted
                        ? _isLastExercise
                              ? 'กลับหน้าหลัก'
                              : 'ดูท่าถัดไป'
                        : widget.day.isRestDay
                        ? 'กลับปฏิทิน'
                        : _saving
                        ? 'กำลังบันทึก...'
                        : _isLastExercise
                        ? 'เสร็จสิ้นและบันทึก'
                        : _isTimedExercise && _remainingSeconds > 0
                        ? 'กำลังฝึก · $_remainingSeconds วินาที'
                        : 'ท่านี้เสร็จแล้ว · ถัดไป',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'ท่าฝึก',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$current / $total',
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 7),
      LinearProgressIndicator(
        value: current / total,
        minHeight: 6,
        borderRadius: BorderRadius.circular(5),
        color: _orange,
        backgroundColor: const Color(0xFFE2E4DB),
      ),
    ],
  );
}

class _ExerciseInstruction extends StatelessWidget {
  const _ExerciseInstruction({
    required this.exercise,
    required this.isCompleted,
  });

  final Exercise exercise;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFE6E9D8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.repeat, color: _ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isCompleted
                ? 'เป้าหมาย: ${exercise.prescription}'
                : 'ทำตามจำนวนที่กำหนด: ${exercise.prescription}',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ExerciseCountdown extends StatelessWidget {
  const _ExerciseCountdown({required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: _ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              remainingSeconds > 0 ? 'ค้างท่าไว้ตามเวลา' : 'ครบเวลาแล้ว',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: _ink,
              fontFeatures: [FontFeature.tabularFigures()],
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key, required this.service});

  final WorkoutViewModel service;

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late Future<List<WorkoutRecord>> _historyTask;
  int _historyGeneration = 0;

  @override
  void initState() {
    super.initState();
    _historyTask = widget.service.fetchWorkouts();
  }

  void _retry() => setState(() {
    _historyTask = widget.service.fetchWorkouts();
    _historyGeneration++;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ประวัติการฝึก')),
    body: SafeArea(
      child: FutureBuilder<List<WorkoutRecord>>(
        key: ValueKey(_historyGeneration),
        future: _historyTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ConnectionError(error: snapshot.error!, onRetry: _retry);
          }
          final workouts = snapshot.data!;
          if (workouts.isEmpty) {
            return const Center(child: _EmptyHistory());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final workout = workouts[index];
              return _WorkoutRow(
                workout,
                onTap: () => _showDetails(workout),
                onEdit: () => _edit(workout),
                onDelete: () => _delete(workout),
              );
            },
          );
        },
      ),
    ),
  );

  Future<void> _showDetails(WorkoutRecord workout) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(workout.title),
      content: Text(
        'วันที่ฝึก: ${workout.completedAt.toLocal()}\n'
        'จำนวนท่า: ${workout.exerciseCount}\n'
        'เวลา: ${workout.durationMinutes} นาที\n'
        'แคลอรีโดยประมาณ: ${workout.caloriesBurned == null ? 'ยังคำนวณไม่ได้ (กรอกน้ำหนักในโปรไฟล์)' : '${workout.caloriesBurned} kcal'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    ),
  );

  Future<void> _edit(WorkoutRecord workout) async {
    final durationMinutes = await showDialog<int>(
      context: context,
      builder: (_) => _EditWorkoutDurationDialog(
        initialDurationMinutes: workout.durationMinutes,
      ),
    );
    if (durationMinutes == null) return;

    try {
      await widget.service.updateWorkout(
        id: workout.id,
        durationMinutes: durationMinutes,
      );
      if (!mounted) return;
      _retry();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตประวัติการฝึกแล้ว')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('แก้ไขไม่สำเร็จ: $error')));
      }
    }
  }

  Future<void> _delete(WorkoutRecord workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบประวัติการฝึก?'),
        content: Text('ต้องการลบ “${workout.title}” หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.service.deleteWorkout(id: workout.id);
      if (!mounted) return;
      _retry();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลบประวัติการฝึกแล้ว')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $error')));
      }
    }
  }
}

class _EditWorkoutDurationDialog extends StatefulWidget {
  const _EditWorkoutDurationDialog({required this.initialDurationMinutes});

  final int initialDurationMinutes;

  @override
  State<_EditWorkoutDurationDialog> createState() =>
      _EditWorkoutDurationDialogState();
}

class _EditWorkoutDurationDialogState
    extends State<_EditWorkoutDurationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialDurationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('แก้ไขเวลาออกกำลังกาย'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'เวลา (นาที)',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          final minutes = int.tryParse(value?.trim() ?? '');
          if (minutes == null || minutes < 1 || minutes > 300) {
            return 'กรอกเวลาระหว่าง 1–300 นาที';
          }
          return null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, int.parse(_controller.text.trim()));
          }
        },
        child: const Text('บันทึก'),
      ),
    ],
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.service});

  final WorkoutViewModel service;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profileTask;

  @override
  void initState() {
    super.initState();
    _profileTask = widget.service.fetchProfile();
  }

  void _retry() => setState(() => _profileTask = widget.service.fetchProfile());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('โปรไฟล์')),
    body: SafeArea(
      child: FutureBuilder<UserProfile>(
        future: _profileTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ConnectionError(error: snapshot.error!, onRetry: _retry);
          }
          return _ProfileForm(
            key: ValueKey(snapshot.data!.email),
            profile: snapshot.data!,
            service: widget.service,
          );
        },
      ),
    ),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key, required this.profile, required this.service});

  final UserProfile profile;
  final WorkoutViewModel service;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  String? _gender;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _gender = widget.profile.gender;
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: _formatNumber(widget.profile.weightKg),
    );
    _heightController = TextEditingController(
      text: _formatNumber(widget.profile.heightCm),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String _formatNumber(double? value) => value == null
      ? ''
      : value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);

  String? _validateNumber(
    String? value, {
    required String label,
    required double minimum,
    required double maximum,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite) return 'กรุณากรอก$labelเป็นตัวเลข';
    if (number < minimum || number > maximum) {
      return 'กรุณากรอก$labelระหว่าง $minimum–$maximum';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await widget.service.updateProfile(
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : int.parse(_ageController.text.trim()),
        weightKg: _weightController.text.trim().isEmpty
            ? null
            : double.parse(_weightController.text.trim()),
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.parse(_heightController.text.trim()),
      );
      if (mounted) {
        setState(() => _saved = true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกโปรไฟล์ไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF34483B),
                child: Icon(Icons.person, color: _lime, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลส่วนตัว',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.email,
                      style: const TextStyle(color: Color(0xFFD5DCD7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          key: const ValueKey('profile-gender'),
          initialValue: _gender,
          decoration: const InputDecoration(
            labelText: 'เพศ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('ชาย')),
            DropdownMenuItem(value: 'female', child: Text('หญิง')),
            DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
            DropdownMenuItem(
              value: 'prefer_not_to_say',
              child: Text('ไม่ประสงค์ระบุ'),
            ),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() {
                  _gender = value;
                  _saved = false;
                }),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('profile-age'),
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'อายุ',
            suffixText: 'ปี',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cake_outlined),
          ),
          onChanged: (_) => setState(() => _saved = false),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final age = int.tryParse(value.trim());
            if (age == null) return 'กรุณากรอกอายุเป็นจำนวนเต็ม';
            if (age < 1 || age > 120) return 'กรุณากรอกอายุระหว่าง 1–120';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('profile-weight'),
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'น้ำหนัก',
            suffixText: 'กก.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight_outlined),
          ),
          onChanged: (_) => setState(() => _saved = false),
          validator: (value) => _validateNumber(
            value,
            label: 'น้ำหนัก',
            minimum: 1,
            maximum: 500,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('profile-height'),
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'ส่วนสูง',
            suffixText: 'ซม.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.height),
          ),
          onChanged: (_) => setState(() => _saved = false),
          validator: (value) => _validateNumber(
            value,
            label: 'ส่วนสูง',
            minimum: 30,
            maximum: 300,
          ),
        ),
        const SizedBox(height: 24),
        if (_saved) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF658344), size: 18),
              SizedBox(width: 7),
              Text(
                'บันทึกโปรไฟล์เรียบร้อยแล้ว',
                style: TextStyle(
                  color: Color(0xFF658344),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('save-profile'),
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
        ),
      ],
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.number});

  final Exercise exercise;
  final int number;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E9D8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    exercise.prescription,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ExerciseIllustration(
          motion: guide.motion,
          label: 'ภาพเคลื่อนไหวสาธิต ${exercise.name}',
        ),
        const SizedBox(height: 14),
        const Text(
          'วิธีทำ',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ...guide.steps.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              '${entry.$1 + 1}. ${entry.$2}',
              style: const TextStyle(color: _ink, height: 1.35),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 7),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 17, color: _orange),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  guide.tip,
                  style: const TextStyle(color: _ink, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  ExerciseGuide get guide => guideForExercise(exercise.id);
}

class _WorkoutTimer extends StatelessWidget {
  const _WorkoutTimer({
    required this.elapsed,
    required this.isRunning,
    required this.onToggle,
  });

  final Duration elapsed;
  final bool isRunning;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: _ink),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'เวลาฝึกของวันนี้',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: _ink,
              fontFeatures: [FontFeature.tabularFigures()],
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: isRunning ? 'หยุดเวลา' : 'เริ่มเวลา',
            onPressed: onToggle,
            icon: Icon(
              isRunning
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow(
    this.workout, {
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkoutRecord workout;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: const Icon(Icons.check_circle, color: Color(0xFF658344), size: 20),
    title: Text(
      workout.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${workout.durationMinutes} นาที · ${workout.caloriesBurned == null ? 'กรอกน้ำหนักเพื่อคำนวณแคลอรี' : '${workout.caloriesBurned} kcal'}',
      style: const TextStyle(color: _muted, fontSize: 12),
    ),
    trailing: PopupMenuButton<String>(
      tooltip: 'จัดการรายการ',
      onSelected: (action) {
        if (action == 'edit') onEdit();
        if (action == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
        PopupMenuItem(value: 'delete', child: Text('ลบ')),
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
      'ยังไม่มีประวัติการฝึก เริ่มวันแรกได้เลย',
      style: TextStyle(color: _muted),
    ),
  );
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 42, color: _orange),
          const SizedBox(height: 14),
          const Text(
            'ยังเชื่อมต่อ backend ไม่ได้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'ตรวจข้อความผิดพลาดด้านล่าง แล้วลองอีกครั้ง',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
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
