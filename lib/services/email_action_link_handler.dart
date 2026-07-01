import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class AuthActionLinkHandler {
  static bool shouldHandle(Uri uri) {
    if (!(uri.host.contains('firebaseapp.com') || uri.host.contains('web.app'))) {
      return false;
    }

    if (!uri.path.contains('/__/auth/action')) {
      return false;
    }

    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'] ?? '';

    return mode == 'verifyEmail' && oobCode.isNotEmpty;
  }

  static Future<({String routeName, Object? arguments})?> resolveRoute(
    Uri uri, {
    Future<bool> Function(Uri uri)? verifyEmailHandler,
  }) async {
    if (!(uri.host.contains('firebaseapp.com') || uri.host.contains('web.app'))) {
      return null;
    }

    if (!uri.path.contains('/__/auth/action')) {
      return null;
    }

    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'] ?? '';

    if (mode == 'verifyEmail' && oobCode.isNotEmpty) {
      await (verifyEmailHandler?.call(uri) ?? handleVerifyEmail(uri));
      return (routeName: AppRoutes.onboarding1, arguments: null);
    }

    if (mode == 'resetPassword' && oobCode.isNotEmpty) {
      return (routeName: AppRoutes.changePassword, arguments: oobCode);
    }

    return null;
  }

  static Future<bool> handleVerifyEmail(Uri uri) async {
    if (!shouldHandle(uri)) return false;

    final oobCode = uri.queryParameters['oobCode'];
    if (oobCode == null || oobCode.isEmpty) return false;

    try {
      await FirebaseAuth.instance.applyActionCode(oobCode);
      return true;
    } catch (_) {
      return false;
    }
  }
}
