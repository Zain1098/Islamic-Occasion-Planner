package com.islamicoccasionplanner.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class OccasionPlannerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.occasion_planner_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("widget_title", "No upcoming occasion"))
                setTextViewText(R.id.widget_subtitle, widgetData.getString("widget_subtitle", "Open Noor to add your first plan"))
                setTextViewText(R.id.widget_amount, widgetData.getString("widget_amount", "Plan ahead, stress less"))
                val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
                setOnClickPendingIntent(R.id.widget_open, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
