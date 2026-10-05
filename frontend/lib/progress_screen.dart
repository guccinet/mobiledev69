import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'workout_api.dart';

const _progressInk = Color(0xFF192A23);
const _progressMuted = Color(0xFF66736C);
const _progressLime = Color(0xFFB7D36B);
const _progressOrange = Color(0xFFE66A3D);

enum ProgressMetric { workouts, minutes, calories }

extension on ProgressMetric {
  String get label => switch (this) {
    ProgressMetric.workouts => 'วันฝึก',
    ProgressMetric.minutes => 'นาที',
    ProgressMetric.calories => 'kcal',
  };

  String get title => switch (this) {
    ProgressMetric.workouts => 'จำนวนวันฝึก',
    ProgressMetric.minutes => 'เวลาออกกำลังกาย',
    ProgressMetric.calories => 'แคลอรีโดยประมาณ',
  };
}

class WorkoutLevelRecommendation {
  const WorkoutLevelRecommendation({
    required this.level,
    required this.reason,
    required this.recentWorkouts,
  });

  final String level;
  final String reason;
  final int recentWorkouts;
}

WorkoutLevelRecommendation recommendWorkoutDifficulty(
  UserProfile profile,
  List<WorkoutRecord> workouts, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final cutoff = reference.subtract(const Duration(days: 28));
  final recentWorkouts = workouts
      .where(
        (workout) =>
            !workout.completedAt.isBefore(cutoff) &&
            !workout.completedAt.isAfter(reference),
      )
      .length;

  if (profile.age == null) {
    return WorkoutLevelRecommendation(
      level: 'เริ่มฝึก',
      reason: 'เพิ่มอายุในโปรไฟล์เพื่อประกอบคำแนะนำเบื้องต้น',
      recentWorkouts: recentWorkouts,
    );
  }
  if (profile.age! < 18 || profile.age! >= 60) {
    return WorkoutLevelRecommendation(
      level: 'เริ่มฝึก',
      reason: 'แนะนำให้เริ่มอย่างค่อยเป็นค่อยไป และเลือกระดับตามความพร้อมของร่างกาย',
      recentWorkouts: recentWorkouts,
    );
  }
  if (recentWorkouts >= 8) {
    return WorkoutLevelRecommendation(
      level: 'ปานกลาง',
      reason:
          'ฝึกสำเร็จ $recentWorkouts ครั้งใน 28 วันที่ผ่านมา ลองระดับปานกลางได้หากรู้สึกพร้อม',
      recentWorkouts: recentWorkouts,
    );
  }
  return WorkoutLevelRecommendation(
    level: 'เริ่มฝึก',
    reason: 'เริ่มจากระดับเริ่มฝึกก่อน แล้วประเมินความพร้อมจากการฝึกจริง',
    recentWorkouts: recentWorkouts,
  );
}

class WorkoutProgressScreen extends StatefulWidget {
  const WorkoutProgressScreen({super.key, required this.service});

  final WorkoutService service;

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  late Future<({UserProfile profile, List<WorkoutRecord> workouts})> _loadTask;
  ProgressMetric _metric = ProgressMetric.workouts;

  @override
  void initState() {
    super.initState();
    _loadTask = _load();
  }

  Future<({UserProfile profile, List<WorkoutRecord> workouts})> _load() async {
    final results = await Future.wait<Object>([
      widget.service.fetchProfile(),
      widget.service.fetchWorkouts(),
    ]);
    return (
      profile: results[0] as UserProfile,
      workouts: results[1] as List<WorkoutRecord>,
    );
  }

  void _retry() => setState(() => _loadTask = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ความก้าวหน้า')),
    body: SafeArea(
      child:
          FutureBuilder<({UserProfile profile, List<WorkoutRecord> workouts})>(
            future: _loadTask,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ProgressError(error: snapshot.error!, onRetry: _retry);
              }
              final data = snapshot.data!;
              return _ProgressContent(
                workouts: data.workouts,
                recommendation: recommendWorkoutDifficulty(
                  data.profile,
                  data.workouts,
                ),
                metric: _metric,
                onMetricChanged: (metric) => setState(() => _metric = metric),
              );
            },
          ),
    ),
  );
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.workouts,
    required this.recommendation,
    required this.metric,
    required this.onMetricChanged,
  });

  final List<WorkoutRecord> workouts;
  final WorkoutLevelRecommendation recommendation;
  final ProgressMetric metric;
  final ValueChanged<ProgressMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final weeklyValues = _weeklyValues(workouts, metric, DateTime.now());
    final metricTotal = weeklyValues.fold<int>(0, (sum, value) => sum + value);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text(
          'ติดตามความสม่ำเสมอของคุณ',
          style: TextStyle(
            color: _progressInk,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'สรุปผลรายสัปดาห์ในช่วง 8 สัปดาห์ล่าสุด',
          style: TextStyle(color: _progressMuted),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.title,
                style: const TextStyle(
                  color: _progressInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ProgressMetric.values
                    .map(
                      (option) => ChoiceChip(
                        key: ValueKey('progress-metric-${option.name}'),
                        label: Text(option.label),
                        selected: metric == option,
                        onSelected: (_) => onMetricChanged(option),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                metric == ProgressMetric.workouts
                    ? '$metricTotal วันฝึกใน 8 สัปดาห์'
                    : '$metricTotal ${metric.label}ใน 8 สัปดาห์',
                style: const TextStyle(
                  color: _progressMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                child: CustomPaint(
                  key: const ValueKey('weekly-progress-chart'),
                  painter: _WeeklyBarChartPainter(
                    values: weeklyValues,
                    color: _progressOrange,
                    gridColor: const Color(0xFFE8EAE4),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              _WeekLabels(startOfFirstWeek: _firstWeekStart(DateTime.now())),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _RecommendationCard(recommendation: recommendation),
      ],
    );
  }

  List<int> _weeklyValues(
    List<WorkoutRecord> allWorkouts,
    ProgressMetric selectedMetric,
    DateTime now,
  ) {
    final currentWeek = _firstWeekStart(now);
    final firstWeek = currentWeek.subtract(const Duration(days: 49));
    final values = List<int>.filled(8, 0);
    for (final workout in allWorkouts) {
      final completedAt = workout.completedAt.toLocal();
      final weekStart = _firstWeekStart(completedAt);
      final weekOffset = weekStart.difference(firstWeek).inDays ~/ 7;
      if (weekOffset < 0 || weekOffset >= values.length) continue;
      values[weekOffset] += switch (selectedMetric) {
        ProgressMetric.workouts => 1,
        ProgressMetric.minutes => workout.durationMinutes,
        ProgressMetric.calories => workout.caloriesBurned,
      };
    }
    return values;
  }

  DateTime _firstWeekStart(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }
}

class _WeekLabels extends StatelessWidget {
  const _WeekLabels({required this.startOfFirstWeek});

  final DateTime startOfFirstWeek;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(8, (index) {
      final week = startOfFirstWeek.add(Duration(days: index * 7));
      return Expanded(
        child: Text(
          '${week.day}/${week.month}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _progressMuted, fontSize: 9),
        ),
      );
    }),
  );
}

class _WeeklyBarChartPainter extends CustomPainter {
  const _WeeklyBarChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<int> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
    const left = 8.0;
    const right = 4.0;
    const top = 12.0;
    const bottom = 12.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = math.max(
      1,
      values.reduce((left, right) => left > right ? left : right),
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = top + chartHeight * row / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(22.0, slotWidth * .48);
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var index = 0; index < values.length; index++) {
      final barHeight = chartHeight * values[index] / maxValue;
      final leftX = left + slotWidth * index + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          leftX,
          top + chartHeight - barHeight,
          barWidth,
          math.max(0, barHeight),
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, barPaint);
      final text = TextPainter(
        text: TextSpan(
          text: '${values[index]}',
          style: const TextStyle(
            color: _progressInk,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          leftX + (barWidth - text.width) / 2,
          math.max(0, top + chartHeight - barHeight - text.height - 3),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final WorkoutLevelRecommendation recommendation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _progressInk,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: _progressLime),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ระดับที่แนะนำ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          recommendation.level,
          style: const TextStyle(
            color: _progressLime,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          recommendation.reason,
          style: const TextStyle(color: Colors.white, height: 1.4),
        ),
        const SizedBox(height: 12),
        const Text(
          'เป็นคำแนะนำเริ่มต้น ไม่ใช่การประเมินทางการแพทย์ เพศและน้ำหนักไม่ได้ใช้ตัดสินระดับโดยตรง หากรู้สึกเจ็บหรือไม่พร้อม ให้พักและเลือกระดับที่เบาลง',
          style: TextStyle(color: Color(0xFFD5DCD7), fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: _progressOrange, size: 42),
          const SizedBox(height: 12),
          const Text(
            'โหลดข้อมูลความก้าวหน้าไม่สำเร็จ',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
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
