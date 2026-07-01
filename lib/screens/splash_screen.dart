import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../services/firestore_service.dart';
import '../services/email_action_link_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static String resolveInitialRoute({
    required bool isEmailVerified,
    required bool onboardingCompleted,
  }) {
    if (!isEmailVerified) {
      return AppRoutes.emailVerification;
    }

    return onboardingCompleted ? AppRoutes.dashboard : AppRoutes.onboarding1;
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _navigated) return;

    try {
      final initialUri = await AppLinks()
          .getInitialLink()
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      if (initialUri != null) {
        final route = await AuthActionLinkHandler.resolveRoute(initialUri);
        if (route != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              await currentUser.reload();
            } catch (_) {}
          }

          final refreshedUser = FirebaseAuth.instance.currentUser;
          if (refreshedUser != null) {
            final onboardingCompleted = await _isOnboardingCompleted(refreshedUser.uid);
            final nextRoute = SplashScreen.resolveInitialRoute(
              isEmailVerified: refreshedUser.emailVerified,
              onboardingCompleted: onboardingCompleted,
            );
            _navigateTo(nextRoute);
            return;
          }

          _navigateTo(route.routeName, arguments: route.arguments);
          return;
        }
      }
    } catch (_) {}

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.reload();
        } catch (_) {}

        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser == null) {
          _navigateTo(AppRoutes.welcome);
          return;
        }

        final onboardingCompleted = await _isOnboardingCompleted(refreshedUser.uid);
        final nextRoute = SplashScreen.resolveInitialRoute(
          isEmailVerified: refreshedUser.emailVerified,
          onboardingCompleted: onboardingCompleted,
        );
        _navigateTo(nextRoute);
      } else {
        _navigateTo(AppRoutes.welcome);
      }
    } catch (_) {
      _navigateTo(AppRoutes.welcome);
    }
  }

  Future<bool> _isOnboardingCompleted(String uid) async {
    try {
      final user = await FirestoreService().getUser(uid);
      return user?.onboardingCompleted ?? false;
    } catch (_) {
      return false;
    }
  }

  void _navigateTo(String route, {Object? arguments}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.darkBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: const Column(
                  children: [
                    ClipOval(
                      child: Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'MediSync',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sinkronkan hidup sehatmu',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
