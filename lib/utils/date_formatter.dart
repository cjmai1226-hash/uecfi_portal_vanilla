class DateFormatter {
  static const List<String> _monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Safely parse a date string into a DateTime object
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr.trim() == 'N/A') {
      return null;
    }
    final cleaned = dateStr.trim();
    try {
      return DateTime.parse(cleaned.toUpperCase());
    } catch (_) {
      try {
        if (cleaned.contains('T') || cleaned.contains('t')) {
          final datePart = cleaned.split(RegExp(r'[Tt]')).first.trim();
          return DateTime.parse(datePart);
        }
      } catch (_) {}
      // Try mm/dd/yyyy or yyyy/mm/dd
      try {
        final parts = cleaned.split(RegExp(r'[-/]'));
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            final y = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final d = int.parse(parts[2].split(RegExp(r'[^0-9]')).first);
            return DateTime(y, m, d);
          } else if (parts[2].length >= 4) {
            final m = int.parse(parts[0]);
            final d = int.parse(parts[1]);
            final y = int.parse(parts[2].substring(0, 4));
            return DateTime(y, m, d);
          }
        }
      } catch (_) {}
      return null;
    }
  }

  /// Calculates dynamic age in years from date of birth
  static int calculateAge(String? dobStr) {
    final birthDate = parseDate(dobStr);
    if (birthDate == null) return 0;

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  /// Format date into standard display string e.g. "Jul 24, 1983"
  static String formatDate(String? dateStr, {String fallback = 'Not specified'}) {
    final dt = parseDate(dateStr);
    if (dt != null) {
      final month = (dt.month >= 1 && dt.month <= 12) ? _monthNames[dt.month] : '';
      return '$month ${dt.day}, ${dt.year}'.trim();
    }

    if (dateStr != null && dateStr.trim().isNotEmpty && dateStr.trim() != 'N/A') {
      return dateStr.trim();
    }

    return fallback;
  }

  /// Format Date of Birth with calculated age e.g. "Jul 24, 1983 (42 years old)"
  static String formatDobWithAge(String? dobStr, {String fallback = 'Not provided'}) {
    final dt = parseDate(dobStr);
    final age = calculateAge(dobStr);

    if (dt != null) {
      final month = (dt.month >= 1 && dt.month <= 12) ? _monthNames[dt.month] : '';
      final formattedDate = '$month ${dt.day}, ${dt.year}'.trim();
      if (age > 0) {
        return '$formattedDate ($age years old)';
      }
      return formattedDate;
    }

    if (dobStr != null && dobStr.trim().isNotEmpty && dobStr.trim() != 'N/A') {
      if (age > 0) {
        return '${dobStr.trim()} ($age years old)';
      }
      return dobStr.trim();
    }

    return fallback;
  }
}
