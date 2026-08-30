package com.example.data.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.example.MainActivity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.remote.CampusWeatherSummary
import java.util.Calendar

data class SmartAlarmCalculation(
    val isAlarmActive: Boolean = true,
    val targetDayOfWeek: Int = 1, // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
    val firstClass: CourseScheduleEntity? = null,
    val classStartTimeString: String = "08:30",
    val calculatedWakeupTimeString: String = "07:10 AM",
    val calculatedWakeup24h: String = "07:10",
    val basePrepMinutes: Int = 45,
    val transitMinutes: Int = 20,
    val weatherBufferMinutes: Int = 15,
    val totalBufferMinutes: Int = 80,
    val weatherSummary: CampusWeatherSummary = CampusWeatherSummary(),
    val weatherAdjustmentEnabled: Boolean = true,
    val justificationMessage: String = "Wake up at 07:10 AM to prepare (45m), transit to venue (20m), with +15m rain delay adjustment."
)

object SmartAlarmManager {

    fun calculateSmartAlarm(
        schedulesForDay: List<CourseScheduleEntity>,
        weather: CampusWeatherSummary,
        basePrepMinutes: Int = 45,
        baseTransitMinutes: Int = 20,
        weatherAdjustmentEnabled: Boolean = true,
        isAlarmEnabled: Boolean = true,
        targetDay: Int = 1
    ): SmartAlarmCalculation {
        val sortedClasses = schedulesForDay.sortedBy { parseTimeToMinutes(it.startTime) }
        val firstClass = sortedClasses.firstOrNull()

        if (firstClass == null) {
            return SmartAlarmCalculation(
                isAlarmActive = false,
                targetDayOfWeek = targetDay,
                firstClass = null,
                classStartTimeString = "No Classes",
                calculatedWakeupTimeString = "No Alarm Needed",
                calculatedWakeup24h = "--:--",
                basePrepMinutes = basePrepMinutes,
                transitMinutes = baseTransitMinutes,
                weatherBufferMinutes = 0,
                totalBufferMinutes = 0,
                weatherSummary = weather,
                weatherAdjustmentEnabled = weatherAdjustmentEnabled,
                justificationMessage = "No scheduled lectures found for this day. Enjoy your morning rest!"
            )
        }

        val classMinutes = parseTimeToMinutes(firstClass.startTime)
        val weatherBuffer = if (weatherAdjustmentEnabled) weather.weatherDelayMinutes else 0
        val totalBuffer = basePrepMinutes + baseTransitMinutes + weatherBuffer

        val wakeupMinutes = (classMinutes - totalBuffer).coerceAtLeast(0)
        val wakeupTimeString = formatMinutesTo12Hour(wakeupMinutes)
        val wakeup24h = String.format("%02d:%02d", wakeupMinutes / 60, wakeupMinutes % 60)

        val weatherReason = if (weatherAdjustmentEnabled && weather.isRaining) {
            "Includes +${weatherBuffer}m early adjustment due to ${weather.weatherCondition.lowercase()}."
        } else if (weatherAdjustmentEnabled && weather.weatherDelayMinutes > 0) {
            "Includes +${weatherBuffer}m advisory adjustment (${weather.weatherCondition})."
        } else {
            "Optimal weather conditions; standard commute buffer applied."
        }

        val justification = "First class ${firstClass.courseCode} at ${firstClass.startTime}. Wakeup at $wakeupTimeString allows ${basePrepMinutes}m prep, ${baseTransitMinutes}m walking to ${firstClass.venue}. $weatherReason"

        return SmartAlarmCalculation(
            isAlarmActive = isAlarmEnabled,
            targetDayOfWeek = targetDay,
            firstClass = firstClass,
            classStartTimeString = firstClass.startTime,
            calculatedWakeupTimeString = wakeupTimeString,
            calculatedWakeup24h = wakeup24h,
            basePrepMinutes = basePrepMinutes,
            transitMinutes = baseTransitMinutes,
            weatherBufferMinutes = weatherBuffer,
            totalBufferMinutes = totalBuffer,
            weatherSummary = weather,
            weatherAdjustmentEnabled = weatherAdjustmentEnabled,
            justificationMessage = justification
        )
    }

    fun parseTimeToMinutes(timeStr: String): Int {
        return try {
            val parts = timeStr.trim().split(":")
            val h = parts[0].toInt()
            val m = if (parts.size > 1) parts[1].toInt() else 0
            (h * 60) + m
        } catch (e: Exception) {
            8 * 60 // default 08:00
        }
    }

    fun formatMinutesTo12Hour(totalMinutes: Int): String {
        val hours24 = (totalMinutes / 60) % 24
        val minutes = totalMinutes % 60
        val amPm = if (hours24 >= 12) "PM" else "AM"
        val hours12 = when {
            hours24 == 0 -> 12
            hours24 > 12 -> hours24 - 12
            else -> hours24
        }
        return String.format("%02d:%02d %s", hours12, minutes, amPm)
    }

    /**
     * Preview / Test Smart Alarm tone & haptic vibration
     */
    fun testAlarmToneAndHaptics(context: Context) {
        try {
            // Play alarm tone safely and release
            val toneGen = ToneGenerator(AudioManager.STREAM_ALARM, 85)
            toneGen.startTone(ToneGenerator.TONE_CDMA_HIGH_L, 1000)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    toneGen.release()
                } catch (_: Exception) {}
            }, 1200)

            // Vibrate device
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val vibrator = vibratorManager.defaultVibrator
                val pattern = longArrayOf(0, 400, 200, 400, 200, 600)
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                val pattern = longArrayOf(0, 400, 200, 400, 200, 600)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
                } else {
                    vibrator.vibrate(pattern, -1)
                }
            }
        } catch (e: Exception) {
            // Tone/vibrator fallback
        }
    }
}
