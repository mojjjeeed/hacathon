import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.app.shared.expense/widget');

  /// Get pending action from widget
  static Future<String> getPendingAction() async {
    try {
      final String action = await _channel.invokeMethod('getPendingAction');
      return action;
    } on PlatformException catch (e) {
      print("Failed to get pending action: '${e.message}'.");
      return null;
    }
  }

  /// Update widget data
  static Future<bool> updateWidgetData({
    @required double totalExpenses,
    @required String currentMonth,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('updateWidgetData', {
        'totalExpenses': totalExpenses,
        'currentMonth': currentMonth,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to update widget data: '${e.message}'.");
      return false;
    }
  }
}
