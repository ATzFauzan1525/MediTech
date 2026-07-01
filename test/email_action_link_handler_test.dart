import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/config/app_config.dart';
import 'package:medisync/services/email_action_link_handler.dart';

void main() {
  group('EmailActionLinkHandler', () {
    test('detects verifyEmail links', () {
      final uri = Uri.parse(
        'https://medisync-f44b1.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=abc123',
      );

      expect(AuthActionLinkHandler.shouldHandle(uri), isTrue);
    });

    test('ignores non verifyEmail links', () {
      final uri = Uri.parse(
        'https://medisync-f44b1.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=abc123',
      );

      expect(AuthActionLinkHandler.shouldHandle(uri), isFalse);
    });

    test('requires an oobCode', () {
      final uri = Uri.parse(
        'https://medisync-f44b1.firebaseapp.com/__/auth/action?mode=verifyEmail',
      );

      expect(AuthActionLinkHandler.shouldHandle(uri), isFalse);
    });

    test('routes resetPassword links to the change password route', () async {
      final uri = Uri.parse(
        'https://medisync-f44b1.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=abc123',
      );

      final target = await AuthActionLinkHandler.resolveRoute(uri);

      expect(target, isNotNull);
      expect(target!.routeName, AppRoutes.changePassword);
      expect(target.arguments, 'abc123');
    });

    test('processes verifyEmail links before returning the onboarding route', () async {
      final uri = Uri.parse(
        'https://medisync-f44b1.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=abc123',
      );

      var handled = false;
      final target = await AuthActionLinkHandler.resolveRoute(
        uri,
        verifyEmailHandler: (_) async {
          handled = true;
          return true;
        },
      );

      expect(handled, isTrue);
      expect(target, isNotNull);
      expect(target!.routeName, AppRoutes.onboarding1);
    });
  });
}
