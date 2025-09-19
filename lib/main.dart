import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'pages/root_app.dart';
import 'scoped_model/expenseScope.dart';
import 'services/widget_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyAppWithWidgetHandling());
}

class MyApp extends StatelessWidget {
  final ExpenseModel myExpenseModel = ExpenseModel();

  @override
  Widget build(BuildContext context) {
    return ScopedModel<ExpenseModel>(
      model: myExpenseModel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootApp(),
      ),
    );
  }
}

class MyAppWithWidgetHandling extends StatefulWidget {
  @override
  _MyAppWithWidgetHandlingState createState() => _MyAppWithWidgetHandlingState();
}

class _MyAppWithWidgetHandlingState extends State<MyAppWithWidgetHandling> {
  final ExpenseModel myExpenseModel = ExpenseModel();

  @override
  void initState() {
    super.initState();
    _handleWidgetAction();
  }

  void _handleWidgetAction() async {
    final action = await WidgetService.getPendingAction();
    if (action != null) {
      // Handle widget actions here
      print('Widget action received: $action');
      
      // Navigate to appropriate page based on action
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          switch (action) {
            case 'add_expense':
              // Navigate to add expense page
              _navigateToAddExpense();
              break;
            case 'quick_food':
              // Navigate to add expense with food category pre-selected
              _navigateToAddExpense(category: 'Food');
              break;
            case 'quick_transport':
              // Navigate to add expense with transport category pre-selected
              _navigateToAddExpense(category: 'Transport');
              break;
            default:
              print('Unknown widget action: $action');
          }
        }
      });
    }
  }

  void _navigateToAddExpense({String category}) {
    // This will be handled by the RootApp widget
    // We'll pass the action through the model
    myExpenseModel.setPendingWidgetAction(category);
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<ExpenseModel>(
      model: myExpenseModel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RootApp(),
      ),
    );
  }
}
