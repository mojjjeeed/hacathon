import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/widget_service.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter/material.dart';

class Expense {
  final int id;
  final String date;
  final String person;
  final String item;
  final String category;
  final String amount;
  final Map<String, String> sharedBy;

  Expense({
    this.id,
    this.date,
    this.person,
    this.item,
    this.category,
    this.amount,
    this.sharedBy,
  });
}

class ExpenseModel extends Model {
  ExpenseModel() {
    setInitValues();
  }
  // convert this to a object approach.
  List<String> _categories = [];
  List<String> _users = [];
  List<Map<String, dynamic>> _expenses = [];
  // for now, only month is added, no year, so a particular month for several years will be considered same
  String _currentMonth = '1';
  String _pendingWidgetAction;

  // Future<SharedPreferences> mySharedPref = SharedPreferences.getInstance();

  List<Map<String, dynamic>> get getExpenses => _expenses;
  List<String> get getCategories => _categories;
  List<String> get getUsers => _users;
  String get getCurrentMonth => _currentMonth;
  String get getPendingWidgetAction => _pendingWidgetAction;

  void setUsers(List<String> userList) {
    _users = userList;
    upDateUserData(true, false, false, false);
    notifyListeners();
  }

  void setCategories(List<String> categoryList) {
    _categories = categoryList;
    upDateUserData(false, true, false, false);
    notifyListeners();
  }

  void resetAll() {
    _categories = [];
    _users = [];
    _expenses = [];
    upDateUserData(true, true, true, false);
    notifyListeners();
  }

  void resetToDemoData() {
    _categories = [];
    _users = [];
    _expenses = [];
    testData();
    upDateUserData(true, true, true, true);
    notifyListeners();
  }

  void addExpense(Map<String, dynamic> newExpenseEntry) {
    _expenses.insert(0, newExpenseEntry);
    sortExpenses();
    upDateUserData(false, false, true, false);
    _updateWidgetData();
    notifyListeners();
  }

  void deleteExpense(int index) {
    _expenses.removeAt(index);
    sortExpenses();
    upDateUserData(false, false, true, false);
    _updateWidgetData();
    notifyListeners();
  }

  void editExpense(int index, Map<String, dynamic> updatedExpenseEntry) {
    _expenses[index] = updatedExpenseEntry;
    sortExpenses();
    upDateUserData(false, false, true, false);
    _updateWidgetData();
    notifyListeners();
  }

  void setCurrentMonth(String cMonth) {
    _currentMonth = cMonth;
    upDateUserData(false, false, false, true);
    calculateShares();
    _updateWidgetData();
    notifyListeners();
  }

  void setPendingWidgetAction(String action) {
    _pendingWidgetAction = action;
    notifyListeners();
  }

  void clearPendingWidgetAction() {
    _pendingWidgetAction = null;
    notifyListeners();
  }

  void setInitValues() {
    SharedPreferences.getInstance().then((prefs) {
      _users = prefs.getStringList('users') ?? [];
      _categories = prefs.getStringList('categories') ?? [];
      _currentMonth = prefs.getString('currentMonth') ?? '1';
      
      // Load expenses if they exist
      String expensesJson = prefs.getString('expenses');
      if (expensesJson != null && expensesJson.isNotEmpty) {
        try {
          _expenses = (json.decode(expensesJson) as Iterable)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } catch (e) {
          print('Error loading expenses: $e');
          _expenses = [];
        }
      } else {
        _expenses = [];
      }
      
      // If no data exists, initialize with test data for demo purposes
      if (_users.isEmpty && _categories.isEmpty && _expenses.isEmpty) {
        testData();
        // Save the test data
        upDateUserData(true, true, true, true);
      }
      
      notifyListeners();
    });
  }

  void upDateUserData(bool u, bool c, bool e, bool d) async {
    SharedPreferences.getInstance().then((prefs) => {
          if (e) prefs.setString('expenses', json.encode(_expenses)),
          if (u) prefs.setStringList('users', _users),
          if (c) prefs.setStringList('categories', _categories),
          if (d) prefs.setString('currentMonth', _currentMonth)
        });
  }

  void newDataLoaded(List<String> uList, List<String> cList, List<Map<String, dynamic>> exList) {
    _users = uList;
    _categories = cList;
    _expenses = exList;
    upDateUserData(true, true, true, false);
    notifyListeners();
  }

  Map<String, Map<String, double>> calculateShares() {
    Map<String, Map<String, double>> tmpStats = {
      "Total Spends": {for (var v in _users) v: 0},
      "Total Owe": {for (var v in _users) v: 0},
      "Net Owe": {for (var v in _users) v: 0}
    };

    for (Map entry in _expenses) {
      // get the current month
      String month = int.parse(entry['date'].split('-')[1]).toString();

      if (_currentMonth != '13' && _currentMonth != month) {
        continue;
      }
      double amount = double.parse(entry["amount"]);
      tmpStats["Total Spends"][entry["person"]] += amount;
      for (MapEntry val in entry["shareBy"].entries) {
        tmpStats["Total Owe"][val.key] += double.parse(val.value);
        tmpStats["Net Owe"][val.key] += double.parse(val.value);
      }
    }

    for (String u in _users) {
      tmpStats["Net Owe"][u] = tmpStats["Total Owe"][u] - tmpStats["Total Spends"][u];
    }

    return tmpStats;
  }

  Map<String, double> calculateCategoryShare() {
    Map<String, double> cShare = {for (var v in _categories) v: 0};
    for (Map entry in _expenses) {
      String month = int.parse(entry['date'].split('-')[1]).toString();

      if (_currentMonth != '13' && _currentMonth != month) {
        continue;
      }
      cShare[entry['category']] += double.parse(entry['amount']);
    }

    Map pieData = <String, double>{};
    for (String en in _categories) {
      pieData[en + " ₹ ${cShare[en]}"] = cShare[en];
    }
    return pieData;
  }

  void sortExpenses() {
    // _expenses
    //     .sort((a, b) => DateFormat("dd-MM-yyyy").parse(a['date']).compareTo(DateFormat("dd-MM-yyyy").parse(b['date'])));
  }

  testData() {
    // used for debug
    _categories = ["Bills", "Food", "Misc"];
    _users = ["John", "Sam", "Will"];

    _expenses = [
      {
        "date": "01-03-2021",
        "person": "Sam",
        "item": "Groceries",
        "category": "Food",
        "amount": "300",
        "shareBy": {"Sam": "100", "Will": "100", "John": "100"}
      },
      {
        "date": "01-03-2021",
        "person": "Will",
        "item": "Water",
        "category": "Food",
        "amount": "210",
        "shareBy": {"Sam": "210"}
      },
      {
        "date": "02-03-2021",
        "person": "Will",
        "item": "Misc",
        "category": "Food",
        "amount": "200",
        "shareBy": {"Will": "200"}
      },
      {
        "date": "02-03-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-03-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-02-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-02-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-02-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-02-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-01-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-01-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
      {
        "date": "02-01-2021",
        "person": "John",
        "item": "Rent",
        "category": "Bills",
        "amount": "66",
        "shareBy": {"Sam": "22", "Will": "22", "John": "22"}
      },
    ];
  }

  void _updateWidgetData() {
    // Calculate total expenses for current month
    double totalExpenses = 0.0;
    for (Map entry in _expenses) {
      String month = int.parse(entry['date'].split('-')[1]).toString();
      if (_currentMonth == '13' || _currentMonth == month) {
        totalExpenses += double.parse(entry['amount']);
      }
    }
    
    // Update widget data
    WidgetService.updateWidgetData(
      totalExpenses: totalExpenses,
      currentMonth: _currentMonth,
    );
  }
}
