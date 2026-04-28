package dev.alexo.symptom_tracker_app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import java.util.Calendar

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.symptom_tracker_app/exact_alarm").setMethodCallHandler { call, result ->
            if (call.method == "canScheduleExactAlarms") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
                    result.success(alarmManager.canScheduleExactAlarms())
                } else {
                    result.success(true)
                }
            } else {
                result.notImplemented()
            }
        }

        // Platform channel for OS-level queries (e.g., first day of week).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.symptom_tracker_app/platform").setMethodCallHandler { call, result ->
            if (call.method == "getFirstDayOfWeek") {
                // Calendar.getFirstDayOfWeek() respects the user's regional
                // preferences. Returns Calendar.SUNDAY (1) through
                // Calendar.SATURDAY (7).
                result.success(Calendar.getInstance().firstDayOfWeek)
            } else {
                result.notImplemented()
            }
        }
    }
}
