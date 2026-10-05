import 'package:home_workout_frontend/home_workout_app.dart';
import 'package:home_workout_frontend/oidc_auth_service.dart';
import 'package:home_workout_frontend/workout_api.dart';

void main() {
  final authService = OidcAuthService();
  runHomeWorkoutApp(
    WorkoutApi(accessTokenProvider: authService.getAccessToken),
    authService: authService,
  );
}
