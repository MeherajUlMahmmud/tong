class Helper {
  // Returns 'YYYY-MM-DD' formatted date
  static String getFormattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Returns month name like 'January', 'February', etc.
  static String getMonthName(int month) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid month: $month');
    }
    return months[month - 1];
  }

  // Returns 'YYYY-MM' formatted string for year and month
  static String formatYearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Returns 'MM' formatted string for month (e.g., '01' for January)
  static String formatMonth(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid month: $month');
    }
    return month.toString().padLeft(2, '0');
  }

  // Converts a date string (in 'YYYY-MM-DD' format) into a readable date like 'September 3, 2024'
  static String formatDateString(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${Helper.getMonthName(date.month)} ${date.day}, ${date.year}";
    } catch (e) {
      return dateString;
    }
  }
}
