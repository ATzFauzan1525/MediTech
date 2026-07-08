import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import 'daily_input_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String? _loadedUid;
  late final AuthProvider _authProvider;

  void _loadHealthDataIfNeeded() {
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      _loadedUid = null;
      return;
    }
    if (uid == _loadedUid) return;

    _loadedUid = uid;
    context.read<HealthProvider>().loadRecords(uid);
  }

  void _handleAuthChanged() {
    _loadHealthDataIfNeeded();
  }

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _authProvider.addListener(_handleAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHealthDataIfNeeded();
      NotificationService.checkAndShowNotification();
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
        final screens = [
          const DashboardScreen(),
          const HistoryScreen(),
          const DailyInputScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: screens,
          ),
          bottomNavigationBar: const MainBottomNav(),
        );
      },
    );
  }
}
