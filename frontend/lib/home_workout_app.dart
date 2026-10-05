import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'workout_api.dart';

void runHomeWorkoutApp(WorkoutService service) {
  runApp(HomeWorkoutApp(service: service));
}

class HomeWorkoutApp extends StatelessWidget {
  const HomeWorkoutApp({super.key, required this.service});

  final WorkoutService service;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF192A23);
    return MaterialApp(
      title: 'Move Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F2EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE66A3D),
          primary: const Color(0xFFE66A3D),
          secondary: const Color(0xFFB7D36B),
          surface: const Color(0xFFF4F2EA),
          onSurface: ink,
        ),
      ),
      home: _WorkoutSession(service: service),
    );
  }
}

class _WorkoutSession extends StatefulWidget {
  const _WorkoutSession({required this.service});

  final WorkoutService service;

  @override
  State<_WorkoutSession> createState() => _WorkoutSessionState();
}

class _WorkoutSessionState extends State<_WorkoutSession> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return LoginScreen(
        service: widget.service,
        onAuthenticated: () => setState(() => _isAuthenticated = true),
      );
    }
    return HomeScreen(
      service: widget.service,
      onSignOut: () => setState(() => _isAuthenticated = false),
    );
  }
}