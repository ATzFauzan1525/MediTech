class TimezoneHelper {
  static String resolveLocalTimezone({String? override}) {
    final value = override?.trim();
    return (value != null && value.isNotEmpty) ? value : 'Asia/Jakarta';
  }
}
