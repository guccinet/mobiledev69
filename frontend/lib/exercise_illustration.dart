import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'exercise_guide.dart';

class ExerciseIllustration extends StatefulWidget {
  const ExerciseIllustration({
    super.key,
    required this.motion,
    required this.label,
  });

  final ExerciseMotion motion;
  final String label;

  @override
  State<ExerciseIllustration> createState() => _ExerciseIllustrationState();
}

class _ExerciseIllustrationState extends State<ExerciseIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    image: true,
    label: '${widget.label}, $_cameraLabel',
    child: Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF192A23),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ExercisePainter(
                  motion: widget.motion,
                  progress: (math.sin(_controller.value * math.pi * 2) + 1) / 2,
                  reducedMotion: MediaQuery.of(context).disableAnimations,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFFB7D36B),
                  size: 17,
                ),
                SizedBox(width: 5),
                Text(
                  'ภาพสาธิตท่าฝึก',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF34483B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  _cameraLabel,
                  style: const TextStyle(
                    color: Color(0xFFEAF0DF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String get _cameraLabel => switch (widget.motion) {
    ExerciseMotion.diamondPushUp => 'มุมมองด้านบน',
    ExerciseMotion.inclinePushUp ||
    ExerciseMotion.wallPushUp => 'มุมมองด้านข้าง',
    _ => 'ลูกศรแสดงทิศทาง',
  };
}

class _Pose {
  const _Pose({
    required this.head,
    required this.shoulder,
    required this.hip,
    required this.leftHand,
    required this.rightHand,
    required this.leftKnee,
    required this.rightKnee,
    required this.leftFoot,
    required this.rightFoot,
  });

  final Offset head;
  final Offset shoulder;
  final Offset hip;
  final Offset leftHand;
  final Offset rightHand;
  final Offset leftKnee;
  final Offset rightKnee;
  final Offset leftFoot;
  final Offset rightFoot;

  _Pose interpolate(_Pose other, double t) => _Pose(
    head: Offset.lerp(head, other.head, t)!,
    shoulder: Offset.lerp(shoulder, other.shoulder, t)!,
    hip: Offset.lerp(hip, other.hip, t)!,
    leftHand: Offset.lerp(leftHand, other.leftHand, t)!,
    rightHand: Offset.lerp(rightHand, other.rightHand, t)!,
    leftKnee: Offset.lerp(leftKnee, other.leftKnee, t)!,
    rightKnee: Offset.lerp(rightKnee, other.rightKnee, t)!,
    leftFoot: Offset.lerp(leftFoot, other.leftFoot, t)!,
    rightFoot: Offset.lerp(rightFoot, other.rightFoot, t)!,
  );
}

const _standing = _Pose(
  head: Offset(50, 22),
  shoulder: Offset(50, 39),
  hip: Offset(50, 65),
  leftHand: Offset(37, 58),
  rightHand: Offset(63, 58),
  leftKnee: Offset(43, 82),
  rightKnee: Offset(57, 82),
  leftFoot: Offset(42, 104),
  rightFoot: Offset(58, 104),
);

const _squat = _Pose(
  head: Offset(50, 28),
  shoulder: Offset(50, 45),
  hip: Offset(50, 68),
  leftHand: Offset(30, 57),
  rightHand: Offset(70, 57),
  leftKnee: Offset(35, 82),
  rightKnee: Offset(65, 82),
  leftFoot: Offset(26, 101),
  rightFoot: Offset(74, 101),
);

const _lunge = _Pose(
  head: Offset(48, 25),
  shoulder: Offset(48, 42),
  hip: Offset(48, 68),
  leftHand: Offset(38, 61),
  rightHand: Offset(58, 61),
  leftKnee: Offset(39, 81),
  rightKnee: Offset(67, 83),
  leftFoot: Offset(35, 104),
  rightFoot: Offset(79, 104),
);

const _wallSit = _Pose(
  head: Offset(43, 38),
  shoulder: Offset(44, 53),
  hip: Offset(48, 72),
  leftHand: Offset(36, 69),
  rightHand: Offset(51, 69),
  leftKnee: Offset(31, 77),
  rightKnee: Offset(60, 77),
  leftFoot: Offset(26, 101),
  rightFoot: Offset(66, 101),
);

const _wallLeanTop = _Pose(
  head: Offset(30, 22),
  shoulder: Offset(37, 40),
  hip: Offset(55, 68),
  leftHand: Offset(14, 48),
  rightHand: Offset(18, 51),
  leftKnee: Offset(48, 85),
  rightKnee: Offset(59, 84),
  leftFoot: Offset(44, 105),
  rightFoot: Offset(64, 105),
);

const _wallLeanLow = _Pose(
  head: Offset(38, 33),
  shoulder: Offset(44, 50),
  hip: Offset(56, 70),
  leftHand: Offset(14, 53),
  rightHand: Offset(18, 56),
  leftKnee: Offset(48, 85),
  rightKnee: Offset(59, 84),
  leftFoot: Offset(44, 105),
  rightFoot: Offset(64, 105),
);

const _inclineTop = _Pose(
  head: Offset(22, 44),
  shoulder: Offset(31, 51),
  hip: Offset(55, 64),
  leftHand: Offset(24, 67),
  rightHand: Offset(30, 68),
  leftKnee: Offset(70, 77),
  rightKnee: Offset(75, 78),
  leftFoot: Offset(91, 94),
  rightFoot: Offset(95, 95),
);

const _inclineLow = _Pose(
  head: Offset(21, 58),
  shoulder: Offset(31, 62),
  hip: Offset(55, 66),
  leftHand: Offset(24, 67),
  rightHand: Offset(30, 68),
  leftKnee: Offset(70, 78),
  rightKnee: Offset(75, 79),
  leftFoot: Offset(91, 94),
  rightFoot: Offset(95, 95),
);

const _pushUpTop = _Pose(
  head: Offset(20, 46),
  shoulder: Offset(30, 52),
  hip: Offset(55, 59),
  leftHand: Offset(29, 77),
  rightHand: Offset(34, 77),
  leftKnee: Offset(69, 62),
  rightKnee: Offset(74, 63),
  leftFoot: Offset(91, 67),
  rightFoot: Offset(94, 68),
);

const _pushUpLow = _Pose(
  head: Offset(20, 60),
  shoulder: Offset(30, 65),
  hip: Offset(55, 63),
  leftHand: Offset(29, 78),
  rightHand: Offset(34, 78),
  leftKnee: Offset(69, 65),
  rightKnee: Offset(74, 65),
  leftFoot: Offset(91, 67),
  rightFoot: Offset(94, 68),
);

const _diamondTop = _Pose(
  head: Offset(50, 21),
  shoulder: Offset(50, 39),
  hip: Offset(50, 65),
  leftHand: Offset(48, 53),
  rightHand: Offset(52, 53),
  leftKnee: Offset(39, 78),
  rightKnee: Offset(61, 78),
  leftFoot: Offset(40, 101),
  rightFoot: Offset(60, 101),
);

const _diamondLow = _Pose(
  head: Offset(50, 28),
  shoulder: Offset(50, 45),
  hip: Offset(50, 67),
  leftHand: Offset(48, 53),
  rightHand: Offset(52, 53),
  leftKnee: Offset(39, 79),
  rightKnee: Offset(61, 79),
  leftFoot: Offset(40, 101),
  rightFoot: Offset(60, 101),
);

const _plankLow = _Pose(
  head: Offset(20, 55),
  shoulder: Offset(30, 60),
  hip: Offset(55, 62),
  leftHand: Offset(27, 76),
  rightHand: Offset(32, 76),
  leftKnee: Offset(70, 64),
  rightKnee: Offset(75, 64),
  leftFoot: Offset(91, 67),
  rightFoot: Offset(94, 68),
);

const _climber = _Pose(
  head: Offset(20, 48),
  shoulder: Offset(30, 54),
  hip: Offset(57, 60),
  leftHand: Offset(29, 78),
  rightHand: Offset(34, 78),
  leftKnee: Offset(47, 64),
  rightKnee: Offset(73, 64),
  leftFoot: Offset(51, 77),
  rightFoot: Offset(94, 68),
);

const _pike = _Pose(
  head: Offset(32, 53),
  shoulder: Offset(38, 61),
  hip: Offset(58, 39),
  leftHand: Offset(34, 87),
  rightHand: Offset(40, 87),
  leftKnee: Offset(72, 60),
  rightKnee: Offset(76, 59),
  leftFoot: Offset(85, 86),
  rightFoot: Offset(90, 85),
);

const _pikeLow = _Pose(
  head: Offset(32, 66),
  shoulder: Offset(38, 68),
  hip: Offset(58, 39),
  leftHand: Offset(34, 87),
  rightHand: Offset(40, 87),
  leftKnee: Offset(72, 60),
  rightKnee: Offset(76, 59),
  leftFoot: Offset(85, 86),
  rightFoot: Offset(90, 85),
);

const _dipHigh = _Pose(
  head: Offset(50, 20),
  shoulder: Offset(50, 38),
  hip: Offset(55, 65),
  leftHand: Offset(39, 72),
  rightHand: Offset(61, 72),
  leftKnee: Offset(39, 76),
  rightKnee: Offset(66, 76),
  leftFoot: Offset(30, 94),
  rightFoot: Offset(77, 94),
);

const _dipLow = _Pose(
  head: Offset(50, 28),
  shoulder: Offset(50, 46),
  hip: Offset(55, 76),
  leftHand: Offset(39, 80),
  rightHand: Offset(61, 80),
  leftKnee: Offset(39, 84),
  rightKnee: Offset(66, 84),
  leftFoot: Offset(30, 101),
  rightFoot: Offset(77, 101),
);

const _plank = _Pose(
  head: Offset(20, 49),
  shoulder: Offset(30, 55),
  hip: Offset(55, 60),
  leftHand: Offset(29, 79),
  rightHand: Offset(34, 79),
  leftKnee: Offset(71, 63),
  rightKnee: Offset(76, 64),
  leftFoot: Offset(91, 67),
  rightFoot: Offset(94, 68),
);

const _crunchUp = _Pose(
  head: Offset(30, 42),
  shoulder: Offset(38, 52),
  hip: Offset(57, 72),
  leftHand: Offset(42, 45),
  rightHand: Offset(46, 45),
  leftKnee: Offset(68, 63),
  rightKnee: Offset(73, 63),
  leftFoot: Offset(82, 70),
  rightFoot: Offset(86, 70),
);

const _crunchDown = _Pose(
  head: Offset(19, 63),
  shoulder: Offset(28, 66),
  hip: Offset(53, 70),
  leftHand: Offset(22, 56),
  rightHand: Offset(27, 56),
  leftKnee: Offset(67, 61),
  rightKnee: Offset(72, 61),
  leftFoot: Offset(81, 70),
  rightFoot: Offset(85, 70),
);

const _legRaiseUp = _Pose(
  head: Offset(15, 68),
  shoulder: Offset(25, 72),
  hip: Offset(52, 72),
  leftHand: Offset(24, 83),
  rightHand: Offset(29, 83),
  leftKnee: Offset(62, 62),
  rightKnee: Offset(67, 62),
  leftFoot: Offset(63, 35),
  rightFoot: Offset(69, 35),
);

const _bridgeUp = _Pose(
  head: Offset(15, 68),
  shoulder: Offset(25, 72),
  hip: Offset(54, 47),
  leftHand: Offset(24, 83),
  rightHand: Offset(29, 83),
  leftKnee: Offset(65, 60),
  rightKnee: Offset(70, 60),
  leftFoot: Offset(83, 78),
  rightFoot: Offset(87, 78),
);

const _bridgeDown = _Pose(
  head: Offset(15, 68),
  shoulder: Offset(25, 72),
  hip: Offset(52, 72),
  leftHand: Offset(24, 83),
  rightHand: Offset(29, 83),
  leftKnee: Offset(64, 69),
  rightKnee: Offset(69, 69),
  leftFoot: Offset(82, 78),
  rightFoot: Offset(86, 78),
);

const _prone = _Pose(
  head: Offset(18, 65),
  shoulder: Offset(28, 69),
  hip: Offset(55, 72),
  leftHand: Offset(7, 76),
  rightHand: Offset(11, 78),
  leftKnee: Offset(72, 72),
  rightKnee: Offset(77, 72),
  leftFoot: Offset(94, 74),
  rightFoot: Offset(97, 76),
);

const _superman = _Pose(
  head: Offset(18, 56),
  shoulder: Offset(29, 62),
  hip: Offset(56, 67),
  leftHand: Offset(9, 43),
  rightHand: Offset(13, 44),
  leftKnee: Offset(73, 58),
  rightKnee: Offset(78, 58),
  leftFoot: Offset(95, 49),
  rightFoot: Offset(98, 51),
);

const _birdDog = _Pose(
  head: Offset(29, 47),
  shoulder: Offset(38, 53),
  hip: Offset(63, 61),
  leftHand: Offset(22, 82),
  rightHand: Offset(8, 54),
  leftKnee: Offset(66, 80),
  rightKnee: Offset(80, 58),
  leftFoot: Offset(96, 50),
  rightFoot: Offset(84, 81),
);

const _birdDogStart = _Pose(
  head: Offset(32, 49),
  shoulder: Offset(40, 55),
  hip: Offset(64, 62),
  leftHand: Offset(33, 81),
  rightHand: Offset(47, 81),
  leftKnee: Offset(61, 80),
  rightKnee: Offset(75, 80),
  leftFoot: Offset(60, 99),
  rightFoot: Offset(75, 99),
);

const _cobraRaised = _Pose(
  head: Offset(22, 42),
  shoulder: Offset(31, 51),
  hip: Offset(56, 72),
  leftHand: Offset(29, 81),
  rightHand: Offset(35, 81),
  leftKnee: Offset(72, 72),
  rightKnee: Offset(77, 72),
  leftFoot: Offset(94, 74),
  rightFoot: Offset(97, 76),
);

const _stretchUp = _Pose(
  head: Offset(50, 22),
  shoulder: Offset(50, 39),
  hip: Offset(50, 65),
  leftHand: Offset(42, 10),
  rightHand: Offset(58, 10),
  leftKnee: Offset(43, 82),
  rightKnee: Offset(57, 82),
  leftFoot: Offset(42, 104),
  rightFoot: Offset(58, 104),
);

class _ExercisePainter extends CustomPainter {
  const _ExercisePainter({
    required this.motion,
    required this.progress,
    required this.reducedMotion,
  });

  final ExerciseMotion motion;
  final double progress;
  final bool reducedMotion;

  _Pose get _pose {
    final amount = reducedMotion ? 0.45 : progress;
    switch (motion) {
      case ExerciseMotion.squat:
        return _standing.interpolate(_squat, amount);
      case ExerciseMotion.wallSit:
        return _wallSit;
      case ExerciseMotion.lunge:
        return _standing.interpolate(_lunge, amount);
      case ExerciseMotion.pushUp:
        return _pushUpTop.interpolate(_pushUpLow, amount);
      case ExerciseMotion.inclinePushUp:
        return _inclineTop.interpolate(_inclineLow, amount);
      case ExerciseMotion.diamondPushUp:
        return _diamondTop.interpolate(_diamondLow, amount);
      case ExerciseMotion.dip:
        return _dipHigh.interpolate(_dipLow, amount);
      case ExerciseMotion.plank:
        return _plank;
      case ExerciseMotion.crunch:
      case ExerciseMotion.bicycle:
        return _crunchDown.interpolate(_crunchUp, amount);
      case ExerciseMotion.legRaise:
        return _prone.interpolate(_legRaiseUp, amount);
      case ExerciseMotion.deadBug:
        return _crunchDown;
      case ExerciseMotion.mountainClimber:
        return _plank.interpolate(_climber, amount);
      case ExerciseMotion.bridge:
        return _bridgeDown.interpolate(_bridgeUp, amount);
      case ExerciseMotion.armCircle:
        final angle = amount * math.pi * 2;
        return _Pose(
          head: _standing.head,
          shoulder: _standing.shoulder,
          hip: _standing.hip,
          leftHand: Offset(
            50 - math.cos(angle) * 20,
            39 + math.sin(angle) * 18,
          ),
          rightHand: Offset(
            50 + math.cos(angle) * 20,
            39 + math.sin(angle) * 18,
          ),
          leftKnee: _standing.leftKnee,
          rightKnee: _standing.rightKnee,
          leftFoot: _standing.leftFoot,
          rightFoot: _standing.rightFoot,
        );
      case ExerciseMotion.calfRaise:
        return _standing.interpolate(
          _Pose(
            head: _standing.head,
            shoulder: _standing.shoulder,
            hip: _standing.hip,
            leftHand: _standing.leftHand,
            rightHand: _standing.rightHand,
            leftKnee: _standing.leftKnee,
            rightKnee: _standing.rightKnee,
            leftFoot: Offset(42, 96),
            rightFoot: Offset(58, 96),
          ),
          amount,
        );
      case ExerciseMotion.pike:
        return _pike.interpolate(_pikeLow, amount);
      case ExerciseMotion.plankUpDown:
        return _plank.interpolate(_plankLow, amount);
      case ExerciseMotion.wallPushUp:
        return _wallLeanTop.interpolate(_wallLeanLow, amount);
      case ExerciseMotion.superman:
        return _prone.interpolate(_superman, amount);
      case ExerciseMotion.snowAngel:
        return _prone.interpolate(
          _Pose(
            head: _prone.head,
            shoulder: _prone.shoulder,
            hip: _prone.hip,
            leftHand: Offset(15 + amount * 28, 76 - amount * 20),
            rightHand: Offset(19 + amount * 28, 78 - amount * 20),
            leftKnee: _prone.leftKnee,
            rightKnee: _prone.rightKnee,
            leftFoot: _prone.leftFoot,
            rightFoot: _prone.rightFoot,
          ),
          amount,
        );
      case ExerciseMotion.swimmer:
        return _prone.interpolate(_superman, amount);
      case ExerciseMotion.birdDog:
        return _birdDogStart.interpolate(_birdDog, amount);
      case ExerciseMotion.cobra:
        return _prone.interpolate(_cobraRaised, amount);
      case ExerciseMotion.stretch:
        return _standing.interpolate(_stretchUp, amount);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const designSize = Size(100, 120);
    final scale = math.min(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    final offset = Offset(
      (size.width - designSize.width * scale) / 2,
      (size.height - designSize.height * scale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    const skin = Color(0xFFE6AD84);
    const skinShade = Color(0xFFC98461);
    const shirt = Color(0xFFB7D36B);
    const shirtShade = Color(0xFF82994B);
    const shorts = Color(0xFF345343);
    const shoe = Color(0xFFF4F2EA);
    const dark = Color(0xFF192A23);
    const floorY = 106.0;
    final floor = Paint()
      ..color = const Color(0xFF496051)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(5, floorY), const Offset(95, floorY), floor);

    final pose = _pose;
    final head = pose.head;
    final shoulder = pose.shoulder;
    final hip = pose.hip;
    final leftHand = pose.leftHand;
    final rightHand = pose.rightHand;
    final leftKnee = pose.leftKnee;
    final rightKnee = pose.rightKnee;
    final leftFoot = pose.leftFoot;
    final rightFoot = pose.rightFoot;
    final faceProfile = _facesSideways;

    void stroke(
      Offset start,
      Offset end,
      Color color,
      double width, {
      StrokeCap cap = StrokeCap.round,
    }) {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = cap
          ..style = PaintingStyle.stroke,
      );
    }

    void drawArrow(Offset start, Offset end) {
      const arrowColor = Color(0xFFFF9A65);
      stroke(start, end, const Color(0xFF192A23), 4.5);
      stroke(start, end, arrowColor, 2.3);
      final vector = end - start;
      if (vector.distance < .1) return;
      final direction = vector / vector.distance;
      final perpendicular = Offset(-direction.dy, direction.dx);
      final head = end - direction * 5.2;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          head.dx + perpendicular.dx * 3.4,
          head.dy + perpendicular.dy * 3.4,
        )
        ..lineTo(
          head.dx - perpendicular.dx * 3.4,
          head.dy - perpendicular.dy * 3.4,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = arrowColor);
    }

    void joint(Offset point, {double radius = 3.2}) {
      canvas.drawCircle(point, radius, Paint()..color = skin);
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = skinShade
          ..strokeWidth = .8
          ..style = PaintingStyle.stroke,
      );
    }

    void drawFoot(Offset knee, Offset ankle, {required bool farSide}) {
      var direction = ankle - knee;
      if (direction.distance < .1) direction = const Offset(1, 0);
      final toeDirection = direction.dx.abs() > direction.dy.abs()
          ? Offset(direction.dx.sign, 0)
          : Offset(direction.dx.sign == 0 ? .35 : direction.dx.sign * .35, .94);
      final toe = ankle + toeDirection * 8;
      final perpendicular = Offset(-toeDirection.dy, toeDirection.dx) * 2.8;
      final shoePath = Path()
        ..moveTo(ankle.dx - perpendicular.dx, ankle.dy - perpendicular.dy)
        ..lineTo(ankle.dx + perpendicular.dx, ankle.dy + perpendicular.dy)
        ..lineTo(
          toe.dx + perpendicular.dx * .65,
          toe.dy + perpendicular.dy * .65,
        )
        ..quadraticBezierTo(
          toe.dx + toeDirection.dx * 2,
          toe.dy + toeDirection.dy * 2,
          toe.dx - perpendicular.dx * .65,
          toe.dy - perpendicular.dy * .65,
        )
        ..close();
      canvas.drawPath(
        shoePath,
        Paint()..color = farSide ? const Color(0xFFB7C0B8) : shoe,
      );
      canvas.drawPath(
        shoePath,
        Paint()
          ..color = dark
          ..strokeWidth = .8
          ..style = PaintingStyle.stroke,
      );
      stroke(
        ankle + perpendicular * .55,
        ankle - perpendicular * .55,
        const Color(0xFFE66A3D),
        1.1,
      );
    }

    void drawHand(Offset wrist, Offset elbow, {required bool farSide}) {
      var direction = wrist - elbow;
      if (direction.distance < .1) direction = const Offset(0, 1);
      direction = direction / direction.distance;
      if (faceProfile && shoulder.dx < hip.dx) {
        direction = const Offset(-1, 0);
      }
      final palm = wrist + direction * 2.1;
      final perpendicular = Offset(-direction.dy, direction.dx);
      final palmPath = Path()
        ..moveTo(
          palm.dx - perpendicular.dx * 2.1,
          palm.dy - perpendicular.dy * 2.1,
        )
        ..lineTo(
          palm.dx + perpendicular.dx * 2.1,
          palm.dy + perpendicular.dy * 2.1,
        )
        ..lineTo(palm.dx + direction.dx * 3, palm.dy + direction.dy * 3)
        ..lineTo(
          palm.dx - perpendicular.dx * 1.5,
          palm.dy - perpendicular.dy * 1.5,
        )
        ..close();
      canvas.drawPath(palmPath, Paint()..color = farSide ? skinShade : skin);
      for (var finger = -1; finger <= 1; finger++) {
        final start = palm + perpendicular * (finger * 1.1);
        final end = start + direction * (finger == 0 ? 4.1 : 3.2);
        stroke(start, end, farSide ? skinShade : skin, 1.35);
      }
      final thumbStart = palm + perpendicular * 1.8;
      stroke(
        thumbStart,
        thumbStart + direction * 2 - perpendicular * 1.5,
        farSide ? skinShade : skin,
        1.5,
      );
    }

    void drawInclineSupport() {
      const support = Color(0xFFE6AD84);
      final frame = Paint()
        ..color = support
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(13, 68), const Offset(39, 68), frame);
      canvas.drawLine(const Offset(13, 72), const Offset(39, 72), frame);
      canvas.drawLine(const Offset(13, 68), const Offset(13, 72), frame);
      canvas.drawLine(const Offset(39, 68), const Offset(39, 72), frame);
      canvas.drawLine(const Offset(16, 72), const Offset(16, 101), frame);
      canvas.drawLine(const Offset(36, 72), const Offset(36, 101), frame);
      canvas.drawLine(const Offset(11, 101), const Offset(41, 101), frame);
      canvas.drawLine(
        const Offset(13, 67),
        const Offset(39, 67),
        Paint()
          ..color = const Color(0xFFF4F2EA)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    void drawDiamondHandPlacement() {
      const center = Offset(50, 53);
      final diamond = Path()
        ..moveTo(50, 47.5)
        ..lineTo(55.5, 53)
        ..lineTo(50, 58.5)
        ..lineTo(44.5, 53)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = const Color(0xFFFF9A65).withValues(alpha: .25),
      );
      canvas.drawPath(
        diamond,
        Paint()
          ..color = const Color(0xFFFF9A65)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke,
      );

      for (final side in const [-1.0, 1.0]) {
        final palm = Offset(center.dx + side * 1.45, center.dy + .4);
        final wrist = Offset(center.dx + side * 2.6, center.dy + 3);
        final handRect = Rect.fromCenter(center: palm, width: 3.5, height: 5.6);
        canvas.drawOval(handRect, Paint()..color = const Color(0xFFE6AD84));
        canvas.drawOval(
          handRect,
          Paint()
            ..color = const Color(0xFFC98461)
            ..strokeWidth = .7
            ..style = PaintingStyle.stroke,
        );
        for (var finger = -1; finger <= 1; finger++) {
          stroke(
            wrist + Offset(finger * .8, 0),
            wrist + Offset(finger * 1.1, -3.8),
            const Color(0xFFE6AD84),
            1,
          );
        }
        stroke(
          palm + Offset(side * 1.2, 1),
          palm + Offset(side * 2.5, 2.8),
          const Color(0xFFE6AD84),
          1.3,
        );
      }
    }

    void drawDiamondArms() {
      stroke(const Offset(42, 41), const Offset(37, 47), dark, 7);
      stroke(const Offset(42, 41), const Offset(37, 47), skinShade, 4.8);
      stroke(const Offset(37, 47), const Offset(48, 53), dark, 6);
      stroke(const Offset(37, 47), const Offset(48, 53), skinShade, 4);
      stroke(const Offset(58, 41), const Offset(63, 47), dark, 7);
      stroke(const Offset(58, 41), const Offset(63, 47), skin, 4.8);
      stroke(const Offset(63, 47), const Offset(52, 53), dark, 6);
      stroke(const Offset(63, 47), const Offset(52, 53), skin, 4);
      canvas.drawCircle(const Offset(37, 47), 2.8, Paint()..color = skinShade);
      canvas.drawCircle(const Offset(63, 47), 2.8, Paint()..color = skin);
    }

    void drawLeg(Offset knee, Offset foot, {required bool farSide}) {
      final shade = farSide ? skinShade : skin;
      stroke(hip, knee, dark, 8.2);
      stroke(hip, knee, shade, 6.2);
      final shortsHem = Offset.lerp(hip, knee, .34)!;
      stroke(hip, shortsHem, dark, 8.6);
      stroke(
        hip,
        shortsHem,
        farSide ? shorts.withValues(alpha: .78) : shorts,
        6.7,
      );
      joint(shortsHem, radius: 2.7);
      stroke(knee, foot, dark, 7.5);
      stroke(knee, foot, shade, 5.8);
      joint(knee, radius: 3.3);
      drawFoot(knee, foot, farSide: farSide);
    }

    void drawArm(Offset hand, {required bool farSide}) {
      final elbow =
          Offset.lerp(shoulder, hand, .52)! +
          Offset(0, hand.dy >= shoulder.dy ? 4 : -4);
      final armColor = farSide ? skinShade : skin;
      stroke(shoulder, elbow, dark, 7.1);
      stroke(shoulder, elbow, armColor, 5.4);
      stroke(elbow, hand, dark, 6.4);
      stroke(elbow, hand, armColor, 4.8);
      joint(elbow, radius: 2.9);
      drawHand(hand, elbow, farSide: farSide);
    }

    void drawTorso() {
      final bodyDirection = hip - shoulder;
      final bodyLength = bodyDirection.distance;
      final axis = bodyLength < .1
          ? const Offset(0, 1)
          : bodyDirection / bodyLength;
      final perpendicular = Offset(-axis.dy, axis.dx);
      final shoulderWidth = faceProfile ? 8.2 : 11.5;
      final waistWidth = faceProfile ? 5.8 : 8.5;
      Offset side(Offset center, double width) =>
          center + perpendicular * width;
      final path = Path()
        ..moveTo(
          side(shoulder, -shoulderWidth).dx,
          side(shoulder, -shoulderWidth).dy,
        )
        ..quadraticBezierTo(
          side(shoulder, -shoulderWidth * 1.12).dx,
          side(shoulder, -shoulderWidth * 1.12).dy,
          side(hip, -waistWidth).dx,
          side(hip, -waistWidth).dy,
        )
        ..quadraticBezierTo(
          hip.dx + axis.dx * 4,
          hip.dy + axis.dy * 4,
          side(hip, waistWidth).dx,
          side(hip, waistWidth).dy,
        )
        ..quadraticBezierTo(
          side(shoulder, shoulderWidth * 1.12).dx,
          side(shoulder, shoulderWidth * 1.12).dy,
          side(shoulder, shoulderWidth).dx,
          side(shoulder, shoulderWidth).dy,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = shirt);
      canvas.drawPath(
        path,
        Paint()
          ..color = shirtShade
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
      stroke(
        side(Offset.lerp(shoulder, hip, .45)!, -shoulderWidth * .25),
        side(Offset.lerp(shoulder, hip, .8)!, -waistWidth * .4),
        const Color(0xFFE3EDC1),
        .9,
      );
      stroke(side(hip, -waistWidth), side(hip, waistWidth), dark, 1.5);
    }

    void drawHead() {
      final radiusX = faceProfile ? 6.2 : 6.6;
      final radiusY = 8.0;
      final headRect = Rect.fromCenter(
        center: head,
        width: radiusX * 2,
        height: radiusY * 2,
      );
      canvas.drawOval(headRect, Paint()..color = skin);
      canvas.drawOval(
        headRect,
        Paint()
          ..color = skinShade
          ..strokeWidth = .8
          ..style = PaintingStyle.stroke,
      );
      final hair = Path()
        ..moveTo(head.dx - radiusX, head.dy + 1)
        ..quadraticBezierTo(
          head.dx - radiusX * .7,
          head.dy - radiusY * 1.35,
          head.dx + radiusX * .5,
          head.dy - radiusY * .85,
        )
        ..quadraticBezierTo(
          head.dx + radiusX * 1.15,
          head.dy - radiusY * .25,
          head.dx + radiusX * .9,
          head.dy + 1,
        )
        ..quadraticBezierTo(
          head.dx,
          head.dy - radiusY * .5,
          head.dx - radiusX,
          head.dy + 1,
        )
        ..close();
      canvas.drawPath(hair, Paint()..color = dark);
      if (motion == ExerciseMotion.diamondPushUp) {
        canvas.drawOval(headRect, Paint()..color = dark);
        stroke(
          Offset(head.dx - 2.5, head.dy - 3.2),
          Offset(head.dx + 2.5, head.dy - 3.2),
          const Color(0xFF496051),
          .9,
        );
      } else if (faceProfile) {
        final facingLeft = head.dx <= shoulder.dx;
        final sign = facingLeft ? -1.0 : 1.0;
        final eye = Offset(head.dx + sign * 3.6, head.dy - .1);
        canvas.drawCircle(eye, .9, Paint()..color = dark);
        final nose = Offset(head.dx + sign * 6.2, head.dy + 2.1);
        stroke(Offset(head.dx + sign * 4.6, head.dy + 1), nose, skinShade, 1.2);
        canvas.drawCircle(
          Offset(head.dx - sign * 5.2, head.dy + 1.1),
          1.7,
          Paint()..color = skinShade,
        );
        stroke(
          Offset(head.dx + sign * 2.4, head.dy + 4),
          Offset(head.dx + sign * 4.2, head.dy + 4.5),
          skinShade,
          .8,
        );
      } else {
        canvas.drawCircle(
          Offset(head.dx - 2.1, head.dy + .9),
          .75,
          Paint()..color = dark,
        );
        canvas.drawCircle(
          Offset(head.dx + 2.1, head.dy + .9),
          .75,
          Paint()..color = dark,
        );
        stroke(
          Offset(head.dx - 1.1, head.dy + 4.2),
          Offset(head.dx + 1.1, head.dy + 4.2),
          skinShade,
          .8,
        );
      }
    }

    final floorShadow = Paint()
      ..color = const Color(0xFF111C16).withValues(alpha: .42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(50, floorY + 1), width: 50, height: 4),
      floorShadow,
    );

    if (motion == ExerciseMotion.inclinePushUp) drawInclineSupport();
    if (motion == ExerciseMotion.diamondPushUp) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 60), width: 35, height: 83),
        Paint()
          ..color = const Color(0xFFF4F2EA).withValues(alpha: .22)
          ..strokeWidth = .7
          ..style = PaintingStyle.stroke,
      );
    }
    drawLeg(rightKnee, rightFoot, farSide: true);
    drawLeg(leftKnee, leftFoot, farSide: false);
    drawArm(rightHand, farSide: true);
    drawTorso();
    if (motion == ExerciseMotion.diamondPushUp) {
      drawDiamondArms();
      drawDiamondHandPlacement();
    } else {
      drawArm(leftHand, farSide: false);
    }
    final neckEnd = Offset.lerp(head, shoulder, .68)!;
    stroke(neckEnd, shoulder, skinShade, 5.5);
    stroke(neckEnd, shoulder, skin, 4.2);
    drawHead();
    _drawMovementArrow(drawArrow);
    canvas.restore();
  }

  void _drawMovementArrow(void Function(Offset, Offset) drawArrow) {
    final movingDown = progress < .5;
    switch (motion) {
      case ExerciseMotion.squat:
      case ExerciseMotion.wallSit:
        drawArrow(
          movingDown ? const Offset(88, 44) : const Offset(88, 71),
          movingDown ? const Offset(88, 71) : const Offset(88, 44),
        );
      case ExerciseMotion.lunge:
        drawArrow(const Offset(57, 91), const Offset(78, 91));
      case ExerciseMotion.inclinePushUp:
        drawArrow(
          movingDown ? const Offset(48, 47) : const Offset(42, 61),
          movingDown ? const Offset(42, 61) : const Offset(48, 47),
        );
      case ExerciseMotion.pushUp:
        drawArrow(
          movingDown ? const Offset(84, 45) : const Offset(84, 70),
          movingDown ? const Offset(84, 70) : const Offset(84, 45),
        );
      case ExerciseMotion.diamondPushUp:
        drawArrow(
          movingDown ? const Offset(74, 66) : const Offset(74, 84),
          movingDown ? const Offset(74, 84) : const Offset(74, 66),
        );
      case ExerciseMotion.plank:
        drawArrow(const Offset(83, 59), const Offset(94, 59));
      case ExerciseMotion.crunch:
      case ExerciseMotion.bicycle:
        drawArrow(
          movingDown ? const Offset(43, 53) : const Offset(43, 75),
          movingDown ? const Offset(43, 75) : const Offset(43, 53),
        );
      case ExerciseMotion.legRaise:
        drawArrow(
          movingDown ? const Offset(87, 76) : const Offset(87, 96),
          movingDown ? const Offset(87, 96) : const Offset(87, 76),
        );
      case ExerciseMotion.deadBug:
      case ExerciseMotion.mountainClimber:
      case ExerciseMotion.birdDog:
        drawArrow(const Offset(52, 66), const Offset(70, 66));
      case ExerciseMotion.bridge:
        drawArrow(
          movingDown ? const Offset(47, 49) : const Offset(47, 78),
          movingDown ? const Offset(47, 78) : const Offset(47, 49),
        );
      case ExerciseMotion.armCircle:
        drawArrow(const Offset(77, 40), const Offset(91, 40));
      case ExerciseMotion.dip:
      case ExerciseMotion.pike:
      case ExerciseMotion.plankUpDown:
        drawArrow(
          movingDown ? const Offset(85, 48) : const Offset(85, 72),
          movingDown ? const Offset(85, 72) : const Offset(85, 48),
        );
      case ExerciseMotion.wallPushUp:
        drawArrow(
          movingDown ? const Offset(57, 46) : const Offset(43, 60),
          movingDown ? const Offset(43, 60) : const Offset(57, 46),
        );
      case ExerciseMotion.calfRaise:
        drawArrow(
          movingDown ? const Offset(87, 81) : const Offset(87, 101),
          movingDown ? const Offset(87, 101) : const Offset(87, 81),
        );
      case ExerciseMotion.superman:
      case ExerciseMotion.snowAngel:
      case ExerciseMotion.swimmer:
        drawArrow(const Offset(40, 55), const Offset(22, 43));
      case ExerciseMotion.cobra:
        drawArrow(
          movingDown ? const Offset(47, 56) : const Offset(47, 79),
          movingDown ? const Offset(47, 79) : const Offset(47, 56),
        );
      case ExerciseMotion.stretch:
        drawArrow(const Offset(69, 45), const Offset(69, 25));
    }
  }

  bool get _facesSideways => switch (motion) {
    ExerciseMotion.pushUp ||
    ExerciseMotion.inclinePushUp ||
    ExerciseMotion.plank ||
    ExerciseMotion.crunch ||
    ExerciseMotion.legRaise ||
    ExerciseMotion.bicycle ||
    ExerciseMotion.deadBug ||
    ExerciseMotion.mountainClimber ||
    ExerciseMotion.bridge ||
    ExerciseMotion.dip ||
    ExerciseMotion.pike ||
    ExerciseMotion.plankUpDown ||
    ExerciseMotion.wallPushUp ||
    ExerciseMotion.superman ||
    ExerciseMotion.snowAngel ||
    ExerciseMotion.birdDog ||
    ExerciseMotion.cobra ||
    ExerciseMotion.swimmer => true,
    _ => false,
  };

  @override
  bool shouldRepaint(_ExercisePainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion;
}
