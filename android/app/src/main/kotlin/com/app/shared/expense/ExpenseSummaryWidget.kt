package com.app.shared.expense

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.app.shared.expense.R
import java.text.NumberFormat
import java.util.*

class ExpenseSummaryWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetText = context.getString(R.string.appwidget_text)
            
            // Get expense data from SharedPreferences
            val prefs = context.getSharedPreferences("expense_data", Context.MODE_PRIVATE)
            val totalExpenses = prefs.getFloat("total_expenses", 0f)
            val currentMonth = prefs.getString("current_month", "1") ?: "1"
            val monthNames = arrayOf(
                "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
            )
            
            val monthName = if (currentMonth.toIntOrNull() in 1..12) {
                monthNames[currentMonth.toInt() - 1]
            } else {
                "All"
            }

            // Construct the RemoteViews object
            val views = RemoteViews(context.packageName, R.layout.expense_summary_widget)
            views.setTextViewText(R.id.appwidget_text, "₹${String.format("%.0f", totalExpenses)}")
            views.setTextViewText(R.id.month_text, monthName)
            views.setTextViewText(R.id.title_text, "Total Expenses")

            // Set up click intent to open the app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
