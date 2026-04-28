package dev.alexo.symptom_tracker_app.glance

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.runBlocking

/// Triggers a widget update when the system date changes (midnight rollover
/// or manual date change). This ensures stale entries from yesterday are
/// cleared without waiting for the hourly updatePeriodMillis cycle.
class DateChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_DATE_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val widget = TodayMoodsWidget()
            val manager = GlanceAppWidgetManager(context)
            runBlocking {
                val ids = manager.getGlanceIds(TodayMoodsWidget::class.java)
                for (id in ids) {
                    widget.update(context, id)
                }
            }
        }
    }
}
