package com.app.shared.expense

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.app.shared.expense/widget"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle widget intents
        val action = intent.getStringExtra("action")
        if (action != null) {
            // Store the action to be handled by Flutter
            val prefs = getSharedPreferences("widget_actions", MODE_PRIVATE)
            prefs.edit().putString("pending_action", action).apply()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        // Handle widget intents when app is already running
        val action = intent.getStringExtra("action")
        if (action != null) {
            val prefs = getSharedPreferences("widget_actions", MODE_PRIVATE)
            prefs.edit().putString("pending_action", action).apply()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingAction" -> {
                    val prefs = getSharedPreferences("widget_actions", MODE_PRIVATE)
                    val action = prefs.getString("pending_action", null)
                    if (action != null) {
                        prefs.edit().remove("pending_action").apply()
                        result.success(action)
                    } else {
                        result.success(null)
                    }
                }
                "updateWidgetData" -> {
                    val totalExpenses = call.argument<Double>("totalExpenses") ?: 0.0
                    val currentMonth = call.argument<String>("currentMonth") ?: "1"
                    
                    val prefs = getSharedPreferences("expense_data", MODE_PRIVATE)
                    prefs.edit()
                        .putFloat("total_expenses", totalExpenses.toFloat())
                        .putString("current_month", currentMonth)
                        .apply()
                    
                    // Update widgets
                    val intent = Intent(this, ExpenseSummaryWidget::class.java)
                    intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    sendBroadcast(intent)
                    
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
