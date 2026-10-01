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

data class EventItem(
    val id: String = "",
    val title: String = "",
    val time: String = "",
    val isCompleted: Boolean = false,
)

data class TodayEventsData(
    val date: String = "",
    val events: List<EventItem> = emptyList(),
    val completedCount: Int = 0,
    val totalCount: Int = 0,
)

class TodayEventsWidget : GlanceAppWidget() {

    override val sizeMode = SizeMode.Responsive(
        setOf(
            DpSize(120.dp, 80.dp),   // Small
            DpSize(200.dp, 120.dp),  // Medium
            DpSize(280.dp, 200.dp),  // Large
        )
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )
        val json = prefs.getString("habits_json", null) // Reusing habits_json key for convenience

        val data = if (json != null) {
            try {
                Gson().fromJson(json, TodayEventsData::class.java)
            } catch (e: Exception) {
                null
            }
        } else null

        provideContent {
            TodayEventsContent(data)
        }
    }

    @Composable
    private fun TodayEventsContent(data: TodayEventsData?) {
        val size = LocalSize.current

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(16.dp)
                .background(GlanceTheme.colors.widgetBackground)
                .padding(12.dp)
                .clickable(actionStartActivity<MainActivity>()),
        ) {
            // Header
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "📅",
                    style = TextStyle(fontSize = 16.sp),
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                Text(
                    text = "Today's Events",
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = GlanceTheme.colors.onSurface,
                    ),
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                if (data != null) {
                    Text(
                        text = "${data.completedCount}/${data.totalCount}",
                        style = TextStyle(
                            fontSize = 12.sp,
                            color = GlanceTheme.colors.secondary,
                        ),
                    )
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (data == null || data.events.isEmpty()) {
                // Empty state
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "No events today",
                        style = TextStyle(
                            fontSize = 13.sp,
                            color = GlanceTheme.colors.secondary,
                        ),
                    )
                }
            } else {
                // Determine how many events to show based on widget size
                val maxItems = when {
                    size.height >= 200.dp -> 6
                    size.height >= 120.dp -> 3
                    else -> 1
                }

                val eventsToShow = data.events.take(maxItems)

                eventsToShow.forEach { event ->
                    EventRow(event)
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }

                if (data.events.size > maxItems) {
                    Text(
                        text = "+${data.events.size - maxItems} more",
                        style = TextStyle(
                            fontSize = 11.sp,
                            color = GlanceTheme.colors.secondary,
                        ),
                    )
                }
            }
        }
    }

    @Composable
    private fun EventRow(event: EventItem) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .cornerRadius(8.dp)
                .background(GlanceTheme.colors.secondaryContainer)
                .padding(horizontal = 10.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = if (event.isCompleted) "✅" else "⬜",
                style = TextStyle(fontSize = 14.sp),
            )
            Spacer(modifier = GlanceModifier.width(8.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = event.title,
                    style = TextStyle(
                        fontSize = 13.sp,
                        color = if (event.isCompleted)
                            GlanceTheme.colors.secondary
                        else
                            GlanceTheme.colors.onSurface,
                    ),
                    maxLines = 1,
                )
                Text(
                    text = event.time,
                    style = TextStyle(
                        fontSize = 11.sp,
                        color = GlanceTheme.colors.secondary,
                    ),
                    maxLines = 1,
                )
            }
        }
    }
}
