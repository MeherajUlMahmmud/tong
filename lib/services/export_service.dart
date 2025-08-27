import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tong/repository/firestore_service.dart';
import 'package:intl/intl.dart';

class ExportService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> exportToCSV(String startDate, String endDate) async {
    try {
      // Fetch data for the date range
      final data = await _fetchDataForRange(startDate, endDate);

      // Generate CSV content
      final csvContent = _generateCSVContent(data);

      // Save to file
      final file = await _saveToFile(
          csvContent, 'expenses_${startDate}_to_${endDate}.csv');

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Expense Data Export');
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<void> exportToJSON(String startDate, String endDate) async {
    try {
      // Fetch data for the date range
      final data = await _fetchDataForRange(startDate, endDate);

      // Generate JSON content
      final jsonContent = jsonEncode(data);

      // Save to file
      final file = await _saveToFile(
          jsonContent, 'expenses_${startDate}_to_${endDate}.json');

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Expense Data Export');
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchDataForRange(
      String startDate, String endDate) async {
    // This would fetch actual data from Firestore
    // For now, returning mock data
    return {
      'exportInfo': {
        'startDate': startDate,
        'endDate': endDate,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      },
      'categories': {
        'food': {'title': 'Food', 'price': 50.0},
        'transport': {'title': 'Transport', 'price': 30.0},
        'shopping': {'title': 'Shopping', 'price': 100.0},
      },
      'expenses': [
        {
          'date': '2024-01-01',
          'category': 'food',
          'count': 2,
          'amount': 100.0,
        },
        {
          'date': '2024-01-01',
          'category': 'transport',
          'count': 1,
          'amount': 30.0,
        },
        {
          'date': '2024-01-02',
          'category': 'shopping',
          'count': 1,
          'amount': 100.0,
        },
      ],
      'summary': {
        'totalExpenses': 230.0,
        'totalDays': 2,
        'averageDaily': 115.0,
        'topCategory': 'food',
      },
    };
  }

  String _generateCSVContent(Map<String, dynamic> data) {
    final StringBuffer csv = StringBuffer();

    // Add header
    csv.writeln('Date,Category,Count,Amount (৳)');

    // Add data rows
    final expenses = data['expenses'] as List;
    for (final expense in expenses) {
      csv.writeln(
          '${expense['date']},${expense['category']},${expense['count']},${expense['amount']}');
    }

    // Add summary
    csv.writeln('');
    csv.writeln('Summary');
    csv.writeln('Total Expenses,${data['summary']['totalExpenses']}');
    csv.writeln('Total Days,${data['summary']['totalDays']}');
    csv.writeln('Average Daily,${data['summary']['averageDaily']}');
    csv.writeln('Top Category,${data['summary']['topCategory']}');

    return csv.toString();
  }

  Future<File> _saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  Future<String> generateReport(String startDate, String endDate) async {
    try {
      final data = await _fetchDataForRange(startDate, endDate);

      final StringBuffer report = StringBuffer();

      // Header
      report.writeln('EXPENSE REPORT');
      report.writeln('=' * 50);
      report.writeln(
          'Period: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(endDate))}');
      report.writeln(
          'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
      report.writeln('');

      // Summary
      report.writeln('SUMMARY');
      report.writeln('-' * 20);
      report.writeln('Total Expenses: ৳${data['summary']['totalExpenses']}');
      report.writeln('Total Days: ${data['summary']['totalDays']}');
      report.writeln('Average Daily: ৳${data['summary']['averageDaily']}');
      report.writeln('Top Category: ${data['summary']['topCategory']}');
      report.writeln('');

      // Detailed breakdown
      report.writeln('DETAILED BREAKDOWN');
      report.writeln('-' * 20);

      final expenses = data['expenses'] as List;
      final categories = data['categories'] as Map<String, dynamic>;

      // Group by category
      final Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
      for (final expense in expenses) {
        final category = expense['category'] as String;
        if (!groupedExpenses.containsKey(category)) {
          groupedExpenses[category] = [];
        }
        groupedExpenses[category]!.add(expense);
      }

      for (final entry in groupedExpenses.entries) {
        final category = entry.key;
        final categoryExpenses = entry.value;
        final categoryData = categories[category];

        report.writeln(
            '${categoryData['title']} (৳${categoryData['price']} per item)');

        double categoryTotal = 0;
        for (final expense in categoryExpenses) {
          report.writeln(
              '  ${expense['date']}: ${expense['count']} items = ৳${expense['amount']}');
          categoryTotal += expense['amount'];
        }
        report.writeln('  Category Total: ৳$categoryTotal');
        report.writeln('');
      }

      return report.toString();
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }
}
