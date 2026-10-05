import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_repository.dart';
import 'home_screen.dart';
import 'oidc_auth_service.dart';
import 'workout_api.dart';
import 'workout_repository.dart';
import 'workout_view_model.dart';

void runHomeWorkoutApp(
  WorkoutService service, {
  OidcAuthService? authService,
}) {
  runApp(HomeWorkoutApp(service: service, authService: authService));
}

class HomeWorkoutApp extends StatelessWidget {
  const HomeWorkoutApp({
    super.key,
    required this.service,
    this.authService,
  });

  final WorkoutService service;
  final OidcAuthService? authService;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF192A23);
    return MultiProvider(
      providers: [
        Provider<OidcAuthService>.value(
          value: authService ?? OidcAuthService(),
        ),
        ProxyProvider<OidcAuthService, AuthRepository>(
          update: (_, service, _) => AuthRepository(service),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthRepository>()),
        ),
        Provider<WorkoutService>.value(value: service),
        ProxyProvider<WorkoutService, WorkoutRepository>(
          update: (_, service, _) => WorkoutRepository(service),
        ),
        ProxyProvider<WorkoutRepository, WorkoutViewModel>(
          update: (_, repository, _) => WorkoutViewModel(repository),
        ),
      ],
      child: MaterialApp(
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
        home: const _WorkoutSession(),
      ),
    );
  }
}

class _WorkoutSession extends StatefulWidget {
  const _WorkoutSession();

  @override
  State<_WorkoutSession> createState() => _WorkoutSessionState();
}

class _WorkoutSessionState extends State<_WorkoutSession> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) {
      return LoginScreen(
        onSignIn: auth.signIn,
        isLoading: auth.isLoading,
        error: auth.error,
      );
    }
    return HomeScreen(
      service: context.read<WorkoutViewModel>(),
      onSignOut: auth.signOut,
    );
  }
}