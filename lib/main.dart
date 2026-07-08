import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/health_provider.dart';
import 'providers/navigation_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/onboarding1_screen.dart';
import 'screens/onboarding2_screen.dart';
import 'screens/daily_input_screen.dart';
import 'screens/result_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/email_action_link_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'dailyReminderTask') {
      try {
        await NotificationService.initialize();
        await NotificationService.showDailyReminder();
      } catch (_) {}
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}

  try {
    await NotificationService.initialize();
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'dailyReminderTask',
      'dailyReminderTask',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (_) {}

  runApp(const MediSyncApp());
}

class MediSyncApp extends StatefulWidget {
  const MediSyncApp({super.key});

  @override
  State<MediSyncApp> createState() => _MediSyncAppState();
}

class _MediSyncAppState extends State<MediSyncApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      final initialUri = await _appLinks
          .getInitialLink()
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }, onError: (err) {});
    } catch (_) {}
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final route = await AuthActionLinkHandler.resolveRoute(uri);
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          route.routeName,
          (route) => false,
          arguments: route.arguments,
        );
      });
      return;
    }

    if (uri.scheme == 'medisync' && uri.host == 'change-password') {
      final oobCode = uri.queryParameters['oobCode'];
      if (oobCode != null && oobCode.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.changePassword,
            (route) => false,
            arguments: oobCode,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'MediSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.emailVerification) {
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(email: email),
            );
          }
          if (settings.name == AppRoutes.changePassword) {
            String oobCode = '';
            bool isAuthenticatedMode = false;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              oobCode = args['oobCode']?.toString() ?? '';
              isAuthenticatedMode = args['isAuthenticatedMode'] == true;
            } else if (settings.arguments is String) {
              oobCode = settings.arguments as String;
            }

            return MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(
                oobCode: oobCode,
                isAuthenticatedMode: isAuthenticatedMode,
              ),
            );
          }
          return null;
        },
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.onboarding1: (context) => const Onboarding1Screen(),
          AppRoutes.onboarding2: (context) => const Onboarding2Screen(),
          AppRoutes.dashboard: (context) => const MainNavigationScreen(),
          AppRoutes.dailyInput: (context) => const DailyInputScreen(),
          AppRoutes.result: (context) => const ResultScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
