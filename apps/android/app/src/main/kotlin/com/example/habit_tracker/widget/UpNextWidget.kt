package com.example.habit_tracker.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import com.example.habit_tracker.MainActivity
import com.google.gson.Gson

data class UpNextData(
    val hasEvent: Boolean = false,
    val title: String = "",
    val startTime: String = "",
    val endTime: String = "",
    val isOngoing: Boolean = false,
    val categoryId: String? = null,
)

class UpNextWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Responsive(
        setOf(
            DpSize(120.dp, 48.dp),   // Small (compact bar)
            DpSize(200.dp, 80.dp),   // Medium
        )
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )
        val json = prefs.getString("up_next_json", null)

        val data = if (json != null) {
            try {
                Gson().fromJson(json, UpNextData::class.java)
            } catch (e: Exception) {
                null
            }
        } else null

        provideContent {
            UpNextContent(data)
        }
    }

    @Composable
    private fun UpNextContent(data: UpNextData?) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(16.dp)
                .background(GlanceTheme.colors.widgetBackground)
                .padding(12.dp)
                .clickable(actionStartActivity<MainActivity>()),
        ) {
            if (data == null || !data.hasEvent) {
                // No upcoming events
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text(
                            text = "✨",
                            style = TextStyle(fontSize = 20.sp),
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "All clear!",
                            style = TextStyle(
                                fontSize = 13.sp,
                                color = GlanceTheme.colors.secondary,
                            ),
                        )
                    }
                }
            } else {
                // Header
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = if (data.isOngoing) "🟢" else "🔵",
                        style = TextStyle(fontSize = 12.sp),
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    Text(
                        text = if (data.isOngoing) "Now" else "Up Next",
                        style = TextStyle(
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = GlanceTheme.colors.secondary,
                        ),
                    )
                }

                Spacer(modifier = GlanceModifier.height(4.dp))

                // Event title
                Text(
                    text = data.title,
                    style = TextStyle(
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = GlanceTheme.colors.onSurface,
                    ),
                    maxLines = 2,
                )

                Spacer(modifier = GlanceModifier.height(2.dp))

                // Time
                val timeText = formatTimeRange(data.startTime, data.endTime)
                Text(
                    text = timeText,
                    style = TextStyle(
                        fontSize = 12.sp,
                        color = GlanceTheme.colors.secondary,
                    ),
                )
            }
        }
    }

    private fun formatTimeRange(startIso: String, endIso: String): String {
        return try {
            val startParts = startIso.substringAfter("T").substringBefore(".").split(":")
            val endParts = endIso.substringAfter("T").substringBefore(".").split(":")

            val startHour = startParts[0].toInt()
            val startMin = startParts[1]
            val endHour = endParts[0].toInt()
            val endMin = endParts[1]

            val startAmPm = if (startHour < 12) "AM" else "PM"
            val endAmPm = if (endHour < 12) "AM" else "PM"
            val startH = if (startHour == 0) 12 else if (startHour > 12) startHour - 12 else startHour
            val endH = if (endHour == 0) 12 else if (endHour > 12) endHour - 12 else endHour

            "$startH:$startMin $startAmPm - $endH:$endMin $endAmPm"
        } catch (e: Exception) {
            ""
        }
    }
}
