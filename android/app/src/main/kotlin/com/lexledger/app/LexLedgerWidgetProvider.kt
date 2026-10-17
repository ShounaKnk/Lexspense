package com.lexledger.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class LexLedgerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val pendingAmount = widgetData.getString("pending_amount", "₹ 0.00")
                val pendingCount = widgetData.getInt("pending_count", 0)

                setTextViewText(R.id.widget_amount, pendingAmount)
                setTextViewText(R.id.widget_count, "$pendingCount pending item(s)")

                // Deep-link intent for "+ Log" button
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("lexledger://add")
                )
                setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
