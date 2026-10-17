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

    // 1. Check for Firestore Timestamp string: "Timestamp(seconds=12345, ...)"
    try {
      final secMatch = RegExp(r'seconds=(\d+)').firstMatch(cleaned);
      if (secMatch != null) {
        final seconds = int.parse(secMatch.group(1)!);
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    } catch (_) {}

    // 2. Direct ISO parse on date part if contains 'T' or 't'
    if (cleaned.contains('T') || cleaned.contains('t')) {
      try {
        final datePart = cleaned.split(RegExp(r'[Tt]')).first.trim();
        final dt = DateTime.tryParse(datePart);
        if (dt != null) return dt;
      } catch (_) {}
    }

    // 3. Try standard DateTime.parse
    try {
      final dt = DateTime.tryParse(cleaned);
      if (dt != null) return dt;
    } catch (_) {}

    // 4. Try yyyy-mm-dd or dd-mm-yyyy or mm/dd/yyyy
    try {
      final parts = cleaned.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final p0 = parts[0].trim();
        final p1 = parts[1].trim();
        final p2Raw = parts[2].trim().split(RegExp(r'[^0-9]')).first;

        if (p0.length == 4) {
          // Year first: yyyy-mm-dd
          final y = int.parse(p0);
          final m = int.parse(p1);
          final d = int.parse(p2Raw);
          if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
            return DateTime(y, m, d);
          }
        } else if (p2Raw.length >= 4) {
          // Year last: dd/mm/yyyy or mm/dd/yyyy
          final y = int.parse(p2Raw.substring(0, 4));
          final val1 = int.parse(p0);
          final val2 = int.parse(p1);
          int m, d;
          if (val1 > 12) {
            // val1 is Day, val2 is Month (dd/mm/yyyy)
            d = val1;
            m = val2;
          } else if (val2 > 12) {
            // val2 is Day, val1 is Month (mm/dd/yyyy)
            d = val2;
            m = val1;
          } else {
            // Both <= 12, default to mm/dd/yyyy
            m = val1;
            d = val2;
          }
          if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
            return DateTime(y, m, d);
          }
        }
      }
    } catch (_) {}

    // 5. Try text month names e.g. "26 Dec 2000", "Dec 26, 2000", "26-Dec-2000"
    try {
      const monthMap = {
        'jan': 1, 'january': 1,
        'feb': 2, 'february': 2,
        'mar': 3, 'march': 3,
        'apr': 4, 'april': 4,
        'may': 5,
        'jun': 6, 'june': 6,
        'jul': 7, 'july': 7,
        'aug': 8, 'august': 8,
        'sep': 9, 'september': 9,
        'oct': 10, 'october': 10,
        'nov': 11, 'november': 11,
        'dec': 12, 'december': 12,
      };
      final tokens = cleaned
          .toLowerCase()
          .split(RegExp(r'[\s\-/,.]+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length >= 3) {
        int? y, m, d;
        for (final token in tokens) {
          if (monthMap.containsKey(token)) {
            m = monthMap[token];
          } else {
            final val = int.tryParse(token);
            if (val != null) {
              if (val > 1000) {
                y = val;
              } else if (d == null) {
                d = val;
              } else {
                y ??= val;
              }
            }
          }
        }
        if (y != null && m != null && d != null && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}

    return null;
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
