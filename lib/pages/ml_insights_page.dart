import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../scoped_model/expenseScope.dart';
import '../services/ml_service.dart';

class MLInsightsPage extends StatefulWidget {
  final ExpenseModel model;
  final Function callback;

  const MLInsightsPage({Key key, @required this.model, this.callback}) : super(key: key);

  @override
  _MLInsightsPageState createState() => _MLInsightsPageState();
}

class _MLInsightsPageState extends State<MLInsightsPage> with TickerProviderStateMixin {
  TabController _tabController;
  List<Map<String, dynamic>> _insights = [];
  List<Map<String, dynamic>> _settlementSuggestions = [];
  Map<String, dynamic> _budgetRecommendations = {};
  Map<String, double> _predictions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMLData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMLData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get insights
      _insights = await MLService.getExpenseInsights(
        widget.model.getExpenses,
        widget.model.getUsers,
      );

      // Get settlement suggestions
      _settlementSuggestions = MLService.generateSettlementSuggestions(
        widget.model.calculateShares(),
        widget.model.getUsers,
      );

      // Get budget recommendations
      _budgetRecommendations = MLService.getBudgetRecommendations(
        widget.model.getExpenses,
        widget.model.getCategories,
      );

      // Get predictions
      _predictions = await MLService.predictNextMonthExpenses(
        widget.model.getExpenses,
        widget.model.getUsers,
        widget.model.getCategories,
      );
    } catch (e) {
      print('Error loading ML data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: myColors[2],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 2.0],
                tileMode: TileMode.clamp,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 50, right: 20, left: 20, bottom: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "AI Insights",
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadMLData,
                      ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: "Insights", icon: Icon(Icons.analytics)),
                      Tab(text: "Settlement", icon: Icon(Icons.account_balance_wallet)),
                      Tab(text: "Budget", icon: Icon(Icons.savings)),
                      Tab(text: "Predictions", icon: Icon(Icons.trending_up)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInsightsTab(),
                      _buildSettlementTab(),
                      _buildBudgetTab(),
                      _buildPredictionsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: myColors[2][0].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      insight['icon'],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        insight['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: black.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹${insight['value'].toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettlementTab() {
    if (_settlementSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: grey),
            SizedBox(height: 16),
            Text(
              "No settlements needed",
              style: TextStyle(fontSize: 18, color: grey),
            ),
            Text(
              "All expenses are balanced!",
              style: TextStyle(fontSize: 14, color: grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _settlementSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _settlementSuggestions[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Icon(Icons.swap_horiz, color: red, size: 24),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Settlement ${index + 1}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        suggestion['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: black.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "₹${suggestion['amount'].toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: green),
                  onPressed: () {
                    _markSettlementComplete(suggestion);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetTab() {
    final recommendations = _budgetRecommendations['recommendations'] ?? {};
    final advice = _budgetRecommendations['advice'] ?? {};
    final totalRecommended = _budgetRecommendations['totalRecommended'] ?? 0.0;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Budget Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: black,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Total Recommended Budget",
                  style: TextStyle(
                    fontSize: 14,
                    color: black.withOpacity(0.7),
                  ),
                ),
                Text(
                  "₹${totalRecommended.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        ...recommendations.entries.map((entry) {
          String category = entry.key;
          double amount = entry.value;
          String categoryAdvice = advice[category] ?? "No specific advice available.";
          
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                      Text(
                        "₹${amount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    categoryAdvice,
                    style: TextStyle(
                      fontSize: 14,
                      color: black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPredictionsTab() {
    if (_predictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: grey),
            SizedBox(height: 16),
            Text(
              "No predictions available",
              style: TextStyle(fontSize: 18, color: grey),
            ),
            Text(
              "Add more expenses to get predictions",
              style: TextStyle(fontSize: 14, color: grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final entry = _predictions.entries.elementAt(index);
        String user = entry.key;
        double predictedAmount = entry.value;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Icon(Icons.person, color: blue, size: 24),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Predicted spending for next month",
                        style: TextStyle(
                          fontSize: 14,
                          color: black.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹${predictedAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.trending_up, color: blue),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markSettlementComplete(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mark as Complete"),
        content: Text("Mark this settlement as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _settlementSuggestions.remove(suggestion);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Settlement marked as complete")),
              );
            },
            child: Text("Complete"),
          ),
        ],
      ),
    );
  }
}
