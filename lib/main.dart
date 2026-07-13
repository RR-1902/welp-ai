import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/interview_provider.dart';
import 'screens/home_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/login_screen.dart';
import 'screens/results_screen.dart';
import 'screens/setup_screen.dart';
import 'services/api_service.dart';
import 'services/camera_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'utils/constants.dart';
import 'package:page_transition/page_transition.dart';

void main() {
  runApp(const InterviewSimulatorApp());
}

class InterviewSimulatorApp extends StatelessWidget {
  const InterviewSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<TtsService>(create: (_) => TtsService()),
        Provider<CameraService>(create: (_) => CameraService()),
        ChangeNotifierProxyProvider4<ApiService, SpeechService, TtsService,
            CameraService, InterviewProvider>(
          create: (_) => InterviewProvider(),
          update: (_, api, speech, tts, camera, provider) =>
              (provider ?? InterviewProvider())
                ..attachServices(
                  apiService: api,
                  speechService: speech,
                  ttsService: tts,
                  cameraService: camera,
                ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppConstants.darkTheme,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case LoginScreen.routeName:
              return _buildRoute(const LoginScreen(), settings);
            case HomeScreen.routeName:
              return _buildRoute(const HomeScreen(), settings);
            case SetupScreen.routeName:
              return _buildRoute(const SetupScreen(), settings);
            case InterviewScreen.routeName:
              return _buildRoute(const InterviewScreen(), settings);
            case ResultsScreen.routeName:
              return _buildRoute(const ResultsScreen(), settings);
          }
          return _buildRoute(const LoginScreen(), settings);
        },
        initialRoute: LoginScreen.routeName,
      ),
    );
  }

  PageRoute<dynamic> _buildRoute(Widget child, RouteSettings settings) {
    return PageTransition(
      settings: settings,
      type: PageTransitionType.rightToLeft,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      child: child,
    );
  }
}
