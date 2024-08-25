import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  Future<void> logDeleteExpense(String tableName, int expenseId) async {
    await _analytics.logEvent(
      name: 'delete_expense',
      parameters: {
        'table_name': tableName,
        'expense_id': expenseId,
      },
    );
  }


  Future<void> logEditedExpense(String tableName, int expenseId) async {
    await _analytics.logEvent(
      name: 'editied_expense',
      parameters: {
        'table_name': tableName,
        'expense_id': expenseId,
      },
    );
  }



  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }






}
