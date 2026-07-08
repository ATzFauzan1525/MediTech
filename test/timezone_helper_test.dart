import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/services/timezone_helper.dart';

void main() {
  test('returns the provided timezone when available', () {
    expect(TimezoneHelper.resolveLocalTimezone(override: 'UTC'), 'UTC');
  });

  test('falls back to Asia/Jakarta when no timezone is provided', () {
    expect(TimezoneHelper.resolveLocalTimezone(override: ''), 'Asia/Jakarta');
  });
}
