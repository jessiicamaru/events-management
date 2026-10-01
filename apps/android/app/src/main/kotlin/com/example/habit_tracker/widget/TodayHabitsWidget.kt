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
import com.google.gson.reflect.TypeToken

data class HabitItem(
    val id: String = "",
    val name: String = "",
    val isCompleted: Boolean = false,
    val totalEvents: Int = 0,
    val currentStreak: Int = 0,
)

data class TodayHabitsData(
    val date: String = "",
    val habits: List<HabitItem> = emptyList(),
    val completedCount: Int = 0,
    val totalCount: Int = 0,
)

class TodayHabitsWidget : GlanceAppWidget() {

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
        val json = prefs.getString("habits_json", null)

        val data = if (json != null) {
            try {
                Gson().fromJson(json, TodayHabitsData::class.java)
            } catch (e: Exception) {
                null
            }
        } else null

        provideContent {
            TodayHabitsContent(data)
        }
    }

    @Composable
    private fun TodayHabitsContent(data: TodayHabitsData?) {
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
                    text = "📋",
                    style = TextStyle(fontSize = 16.sp),
                )
                Spacer(modifier = GlanceModifier.width(6.dp))
                Text(
                    text = "Today's Habits",
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

            if (data == null || data.habits.isEmpty()) {
                // Empty state
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "No habits today",
                        style = TextStyle(
                            fontSize = 13.sp,
                            color = GlanceTheme.colors.secondary,
                        ),
                    )
                }
            } else {
                // Determine how many habits to show based on widget size
                val maxItems = when {
                    size.height >= 200.dp -> 6
                    size.height >= 120.dp -> 3
                    else -> 1
                }

                val habitsToShow = data.habits.take(maxItems)

                habitsToShow.forEach { habit ->
                    HabitRow(habit)
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }

                if (data.habits.size > maxItems) {
                    Text(
                        text = "+${data.habits.size - maxItems} more",
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
    private fun HabitRow(habit: HabitItem) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .cornerRadius(8.dp)
                .background(GlanceTheme.colors.secondaryContainer)
                .padding(horizontal = 10.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = if (habit.isCompleted) "✅" else "⬜",
                style = TextStyle(fontSize = 14.sp),
            )
            Spacer(modifier = GlanceModifier.width(8.dp))
            Text(
                text = habit.name,
                style = TextStyle(
                    fontSize = 13.sp,
                    color = if (habit.isCompleted)
                        GlanceTheme.colors.secondary
                    else
                        GlanceTheme.colors.onSurface,
                ),
                maxLines = 1,
            )
            if (habit.currentStreak > 0) {
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "🔥${habit.currentStreak}",
                    style = TextStyle(
                        fontSize = 11.sp,
                        color = GlanceTheme.colors.secondary,
                    ),
                )
            }
        }
    }
}
