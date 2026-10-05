import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'workout_api.dart';
import 'workout_view_model.dart';

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

bool isWeightUpdateDue(List<WeightEntry> entries, {DateTime? now}) {
  if (entries.isEmpty) return true;
  final reference = now ?? DateTime.now();
  final latest = entries.last.recordedAt.toLocal();
  final today = DateTime(reference.year, reference.month, reference.day);
  final lastRecordedDay = DateTime(latest.year, latest.month, latest.day);
  return today.difference(lastRecordedDay).inDays >= 7;
}

class WorkoutProgressScreen extends StatefulWidget {
  const WorkoutProgressScreen({super.key, required this.service});

  final WorkoutViewModel service;

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  late Future<
    ({
      UserProfile profile,
      List<WorkoutRecord> workouts,
      List<WeightEntry> weights,
    })
  >
  _loadTask;
  ProgressMetric _metric = ProgressMetric.workouts;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadTask = _load();
  }

  Future<
    ({
      UserProfile profile,
      List<WorkoutRecord> workouts,
      List<WeightEntry> weights,
    })
  >
  _load() async {
    _loadGeneration++;
    final results = await Future.wait<Object>([
      widget.service.fetchProfile(),
      widget.service.fetchWorkouts(),
      widget.service.fetchWeightHistory(),
    ]);
    return (
      profile: results[0] as UserProfile,
      workouts: results[1] as List<WorkoutRecord>,
      weights: results[2] as List<WeightEntry>,
    );
  }

  void _retry() => setState(() {
    _loadTask = _load();
  });

  Future<void> _recordWeight(double weightKg) async {
    await widget.service.recordWeight(weightKg: weightKg);
    if (!mounted) return;
    setState(() {
      _loadTask = _load();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกน้ำหนักเรียบร้อยแล้ว')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ความก้าวหน้า')),
    body: SafeArea(
      child:
          FutureBuilder<
            ({
              UserProfile profile,
              List<WorkoutRecord> workouts,
              List<WeightEntry> weights,
            })
          >(
            key: ValueKey(_loadGeneration),
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
                profile: data.profile,
                workouts: data.workouts,
                weights: data.weights,
                recommendation: recommendWorkoutDifficulty(
                  data.profile,
                  data.workouts,
                ),
                metric: _metric,
                onMetricChanged: (metric) => setState(() => _metric = metric),
                onRecordWeight: _recordWeight,
              );
            },
          ),
    ),
  );
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.workouts,
    required this.weights,
    required this.recommendation,
    required this.metric,
    required this.onMetricChanged,
    required this.onRecordWeight,
    required this.profile,
  });

  final List<WorkoutRecord> workouts;
  final List<WeightEntry> weights;
  final UserProfile profile;
  final WorkoutLevelRecommendation recommendation;
  final ProgressMetric metric;
  final ValueChanged<ProgressMetric> onMetricChanged;
  final Future<void> Function(double weightKg) onRecordWeight;

  @override
  Widget build(BuildContext context) {
    final weeklyValues = _weeklyValues(workouts, metric, DateTime.now());
    final metricTotal = weeklyValues.fold<int>(0, (sum, value) => sum + value);
    final weightDue = isWeightUpdateDue(weights);
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
        _WeightTrackingCard(
          entries: weights,
          isDue: weightDue,
          profileWeightKg: profile.weightKg,
          onRecord: onRecordWeight,
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
              if (metric == ProgressMetric.calories) ...[
                const SizedBox(height: 6),
                const Text(
                  'แคลอรีคำนวณด้วยสูตร MET รายการที่ไม่มีน้ำหนักจะไม่นำมารวมในยอด',
                  style: TextStyle(color: _progressMuted, fontSize: 12),
                ),
              ],
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
        ProgressMetric.calories => workout.caloriesBurned ?? 0,
      };
    }
    return values;
  }

  DateTime _firstWeekStart(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }
}

class _WeightTrackingCard extends StatefulWidget {
  const _WeightTrackingCard({
    required this.entries,
    required this.isDue,
    required this.profileWeightKg,
    required this.onRecord,
  });

  final List<WeightEntry> entries;
  final bool isDue;
  final double? profileWeightKg;
  final Future<void> Function(double weightKg) onRecord;

  @override
  State<_WeightTrackingCard> createState() => _WeightTrackingCardState();
}

class _WeightTrackingCardState extends State<_WeightTrackingCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.profileWeightKg?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onRecord(double.parse(_weightController.text.trim()));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกน้ำหนักไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.entries.isEmpty ? null : widget.entries.last;
    final difference = widget.entries.length < 2
        ? null
        : widget.entries.last.weightKg - widget.entries.first.weightKg;
    return Container(
      key: const ValueKey('weight-tracking-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ติดตามน้ำหนัก',
            style: TextStyle(
              color: _progressInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isDue
                ? 'ถึงเวลาอัปเดตน้ำหนักประจำสัปดาห์แล้ว'
                : latest == null
                ? 'บันทึกน้ำหนักเพื่อเริ่มดูแนวโน้ม'
                : 'บันทึกล่าสุด ${_dateLabel(latest.recordedAt)}',
            style: TextStyle(
              color: widget.isDue ? _progressOrange : _progressMuted,
              fontWeight: widget.isDue ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          if (difference != null) ...[
            const SizedBox(height: 6),
            Text(
              'เปลี่ยนแปลง ${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)} กก. จากครั้งแรก',
              style: const TextStyle(color: _progressMuted),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.entries.length >= 2)
            Column(
              children: [
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    key: const ValueKey('weight-history-chart'),
                    painter: _WeightLineChartPainter(
                      weights: widget.entries
                          .map((entry) => entry.weightKg)
                          .toList(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateLabel(widget.entries.first.recordedAt),
                      style: const TextStyle(
                        color: _progressMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _dateLabel(widget.entries.last.recordedAt),
                      style: const TextStyle(
                        color: _progressMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              key: const ValueKey('weight-history-empty-chart'),
              height: 96,
              alignment: Alignment.center,
              child: const Text(
                'เพิ่มบันทึกรายสัปดาห์เพื่อสร้างกราฟ',
                style: TextStyle(color: _progressMuted),
              ),
            ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('weight-entry-input'),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนักวันนี้',
                      suffixText: 'กก.',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      final weight = double.tryParse(value?.trim() ?? '');
                      if (weight == null || !weight.isFinite) {
                        return 'กรอกน้ำหนักเป็นตัวเลข';
                      }
                      if (weight < 1 || weight > 500) {
                        return 'น้ำหนักต้องอยู่ระหว่าง 1–500 กก.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: const ValueKey('record-weight-button'),
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _progressInk,
                    minimumSize: const Size(76, 48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'บันทึกได้ทุกเมื่อ ระบบจะแจ้งเตือนในแอปเมื่อครบ 7 วัน',
            style: TextStyle(color: _progressMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final date = value.toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _WeightLineChartPainter extends CustomPainter {
  const _WeightLineChartPainter({required this.weights});

  final List<double> weights;

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2 || size.isEmpty) return;
    const left = 28.0;
    const right = 12.0;
    const top = 14.0;
    const bottom = 14.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final minimum = weights.reduce(math.min);
    final maximum = weights.reduce(math.max);
    final range = math.max(maximum - minimum, 1.0);
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EAE4)
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final y = top + chartHeight * row / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    final points = List<Offset>.generate(weights.length, (index) {
      final x = left + chartWidth * index / (weights.length - 1);
      final y = top + chartHeight * (maximum - weights[index]) / range;
      return Offset(x, y);
    });
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _progressOrange
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final pointPaint = Paint()..color = _progressOrange;
    final labelStyle = const TextStyle(
      color: _progressInk,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 4, pointPaint);
      final label = TextPainter(
        text: TextSpan(
          text: weights[index].toStringAsFixed(1),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelY = points[index].dy < top + 24
          ? points[index].dy + 6
          : points[index].dy - label.height - 6;
      label.paint(canvas, Offset(points[index].dx - label.width / 2, labelY));
    }
  }

  @override
  bool shouldRepaint(_WeightLineChartPainter oldDelegate) =>
      oldDelegate.weights != weights;
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
