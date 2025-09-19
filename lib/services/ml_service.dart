import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MLService {
  static const String _expenseHistoryKey = 'expense_history';
  static const String _predictionModelKey = 'prediction_model';
  
  // Simple ML model for expense prediction
  static Map<String, dynamic> _predictionModel = {
    'categoryAverages': {},
    'monthlyTrends': {},
    'userPatterns': {},
    'seasonalFactors': {},
  };

  /// Predict next month's expenses based on historical data
  static Future<Map<String, double>> predictNextMonthExpenses(
    List<Map<String, dynamic>> expenses,
    List<String> users,
    List<String> categories,
  ) async {
    await _loadModel();
    await _trainModel(expenses, users, categories);
    
    Map<String, double> predictions = {};
    
    // Predict for each category
    for (String category in categories) {
      double baseAmount = _predictionModel['categoryAverages'][category] ?? 0.0;
      double trendFactor = _getTrendFactor(category);
      double seasonalFactor = _getSeasonalFactor(category);
      
      predictions[category] = baseAmount * trendFactor * seasonalFactor;
    }
    
    // Predict total per user
    Map<String, double> userPredictions = {};
    for (String user in users) {
      double total = 0.0;
      for (String category in categories) {
        double userShare = _getUserSharePattern(user, category);
        total += predictions[category] * userShare;
      }
      userPredictions[user] = total;
    }
    
    await _saveModel();
    return userPredictions;
  }

  /// Get expense insights and recommendations
  static Future<List<Map<String, dynamic>>> getExpenseInsights(
    List<Map<String, dynamic>> expenses,
    List<String> users,
  ) async {
    List<Map<String, dynamic>> insights = [];
    
    // Calculate spending patterns
    Map<String, double> userTotals = {};
    Map<String, double> categoryTotals = {};
    Map<String, int> frequencyCount = {};
    
    for (var expense in expenses) {
      String user = expense['person'];
      String category = expense['category'];
      double amount = double.parse(expense['amount']);
      
      userTotals[user] = (userTotals[user] ?? 0) + amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      frequencyCount[category] = (frequencyCount[category] ?? 0) + 1;
    }
    
    // Find top spender
    String topSpender = userTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    insights.add({
      'type': 'top_spender',
      'title': 'Top Spender',
      'message': '$topSpender spent the most this month',
      'value': userTotals[topSpender],
      'icon': '👑',
    });
    
    // Find most expensive category
    String topCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    insights.add({
      'type': 'top_category',
      'title': 'Highest Spending Category',
      'message': 'Most money spent on $topCategory',
      'value': categoryTotals[topCategory],
      'icon': '📊',
    });
    
    // Find most frequent category
    String frequentCategory = frequencyCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    insights.add({
      'type': 'frequent_category',
      'title': 'Most Frequent Expense',
      'message': 'Most transactions in $frequentCategory',
      'value': frequencyCount[frequentCategory].toDouble(),
      'icon': '🔄',
    });
    
    // Calculate average expense
    double totalAmount = expenses.fold(0.0, (sum, expense) => 
        sum + double.parse(expense['amount']));
    double averageExpense = totalAmount / expenses.length;
    insights.add({
      'type': 'average_expense',
      'title': 'Average Expense',
      'message': 'Average amount per transaction',
      'value': averageExpense,
      'icon': '📈',
    });
    
    return insights;
  }

  /// Generate smart settlement suggestions
  static List<Map<String, dynamic>> generateSettlementSuggestions(
    Map<String, Map<String, double>> shareStats,
    List<String> users,
  ) {
    List<Map<String, dynamic>> suggestions = [];
    
    // Calculate net balances
    Map<String, double> netBalances = {};
    for (String user in users) {
      double totalSpent = (shareStats['Total Spends'] != null && shareStats['Total Spends'][user] != null) 
          ? shareStats['Total Spends'][user] : 0.0;
      double totalOwed = (shareStats['Total Owe'] != null && shareStats['Total Owe'][user] != null) 
          ? shareStats['Total Owe'][user] : 0.0;
      netBalances[user] = totalOwed - totalSpent;
    }
    
    // Find who owes what to whom
    List<Map<String, dynamic>> debts = [];
    List<Map<String, dynamic>> credits = [];
    
    netBalances.forEach((user, balance) {
      if (balance > 0) {
        credits.add({'user': user, 'amount': balance});
      } else if (balance < 0) {
        debts.add({'user': user, 'amount': -balance});
      }
    });
    
    // Sort by amount
    credits.sort((a, b) => b['amount'].compareTo(a['amount']));
    debts.sort((a, b) => b['amount'].compareTo(a['amount']));
    
    // Generate optimal settlement suggestions
    int creditIndex = 0;
    int debtIndex = 0;
    
    while (creditIndex < credits.length && debtIndex < debts.length) {
      var creditor = credits[creditIndex];
      var debtor = debts[debtIndex];
      
      double settlementAmount = min(creditor['amount'], debtor['amount']);
      
      suggestions.add({
        'from': debtor['user'],
        'to': creditor['user'],
        'amount': settlementAmount,
        'description': '${debtor['user']} should pay ₹${settlementAmount.toStringAsFixed(0)} to ${creditor['user']}',
      });
      
      creditor['amount'] -= settlementAmount;
      debtor['amount'] -= settlementAmount;
      
      if (creditor['amount'] <= 0.01) creditIndex++;
      if (debtor['amount'] <= 0.01) debtIndex++;
    }
    
    return suggestions;
  }

  /// Get budget recommendations
  static Map<String, dynamic> getBudgetRecommendations(
    List<Map<String, dynamic>> expenses,
    List<String> categories,
  ) {
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCounts = {};
    
    // Calculate category statistics
    for (var expense in expenses) {
      String category = expense['category'];
      double amount = double.parse(expense['amount']);
      
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    
    double totalSpent = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    Map<String, double> recommendations = {};
    Map<String, String> advice = {};
    
    for (String category in categories) {
      double spent = categoryTotals[category] ?? 0.0;
      double percentage = totalSpent > 0 ? (spent / totalSpent) * 100 : 0.0;
      
      // Recommend budget based on spending patterns
      double recommendedBudget = spent * 1.1; // 10% buffer
      
      recommendations[category] = recommendedBudget;
      
      if (percentage > 50) {
        advice[category] = 'High spending in this category. Consider reducing expenses.';
      } else if (percentage < 10) {
        advice[category] = 'Low spending. You can allocate more budget here if needed.';
      } else {
        advice[category] = 'Balanced spending. Keep monitoring this category.';
      }
    }
    
    return {
      'recommendations': recommendations,
      'advice': advice,
      'totalRecommended': recommendations.values.fold(0.0, (sum, amount) => sum + amount),
    };
  }

  // Private helper methods
  static Future<void> _loadModel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String modelJson = prefs.getString(_predictionModelKey);
    if (modelJson != null) {
      _predictionModel = Map<String, dynamic>.from(json.decode(modelJson));
    }
  }

  static Future<void> _saveModel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_predictionModelKey, json.encode(_predictionModel));
  }

  static Future<void> _trainModel(
    List<Map<String, dynamic>> expenses,
    List<String> users,
    List<String> categories,
  ) async {
    // Calculate category averages
    Map<String, List<double>> categoryAmounts = {};
    for (String category in categories) {
      categoryAmounts[category] = [];
    }
    
    for (var expense in expenses) {
      String category = expense['category'];
      double amount = double.parse(expense['amount']);
      categoryAmounts[category]?.add(amount);
    }
    
    for (String category in categories) {
      List<double> amounts = categoryAmounts[category] ?? [];
      if (amounts.isNotEmpty) {
        double average = amounts.reduce((a, b) => a + b) / amounts.length;
        _predictionModel['categoryAverages'][category] = average;
      }
    }
    
    // Calculate user share patterns
    Map<String, Map<String, double>> userShares = {};
    for (String user in users) {
      userShares[user] = {};
      for (String category in categories) {
        if (userShares[user] != null) {
          userShares[user][category] = 1.0 / users.length; // Default equal share
        }
      }
    }
    
    for (var expense in expenses) {
      String user = expense['person'];
      String category = expense['category'];
      Map<String, String> shareBy = Map<String, String>.from(expense['shareBy']);
      
      double userShare = 0.0;
      if (shareBy.containsKey(user)) {
        userShare = double.parse(shareBy[user]) / double.parse(expense['amount']);
      }
      
      if (userShares[user] != null) {
        userShares[user][category] = userShare;
      }
    }
    
    _predictionModel['userPatterns'] = userShares;
  }

  static double _getTrendFactor(String category) {
    // Simple trend calculation - in a real app, this would be more sophisticated
    return 1.0 + (Random().nextDouble() - 0.5) * 0.2; // ±10% variation
  }

  static double _getSeasonalFactor(String category) {
    // Simple seasonal adjustment
    DateTime now = DateTime.now();
    int month = now.month;
    
    // Example seasonal factors
    Map<String, List<double>> seasonalFactors = {
      'Food': [1.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.2, 1.3],
      'Bills': [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
      'Misc': [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
    };
    
    if (seasonalFactors[category] != null && month > 0 && month <= seasonalFactors[category].length) {
      return seasonalFactors[category][month - 1];
    }
    return 1.0;
  }

  static double _getUserSharePattern(String user, String category) {
    Map<String, dynamic> userPatterns = _predictionModel['userPatterns'] ?? {};
    Map<String, dynamic> userShares = userPatterns[user] ?? {};
    return (userShares[category] ?? 0.0).toDouble();
  }
}
