package dev.alexo.symptom_tracker_app.glance

import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.actionStartActivity
import dev.alexo.symptom_tracker_app.MainActivity
import org.json.JSONArray
import java.time.LocalDate

/// Today's Moods widget — mirrors the calendar screen's entry list for today.
/// Each row shows: time | mood - symptoms.
/// Header has a "+" button that opens the entry screen directly.
/// Tapping an entry opens its detail screen.
/// Supports independent theme selection (light/dark/system).
class TodayMoodsWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                GlanceContent(context, currentState())
            }
        }
    }

    /// Resolves whether to use dark colors based on the widget's theme
    /// preference (independent from the app's theme and system theme).
    private fun isDarkMode(context: Context, themeValue: String): Boolean {
        return when (themeValue) {
            WidgetThemeLight -> false
            WidgetThemeDark -> true
            else -> {
                val nightMode = context.resources.configuration.uiMode and
                        Configuration.UI_MODE_NIGHT_MASK
                nightMode == Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val entriesJson = prefs.getString("widget_today_entries", null)
        val storedDate = prefs.getString("widget_today_date", null)
        val theme = prefs.getString(WidgetThemeKey, WidgetThemeSystem) ?: WidgetThemeSystem
        val dark = isDarkMode(context, theme)

        val backgroundColor = if (dark) WidgetDarkBackground else WidgetLightBackground
        val onSurfaceColor = if (dark) WidgetDarkOnSurface else WidgetLightOnSurface

        // Check if stored data is from today — show empty state if stale.
        val isStale = storedDate != LocalDate.now().toString()

        val entries = mutableListOf<EntryData>()
        if (!isStale && entriesJson != null) {
            try {
                val arr = JSONArray(entriesJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    entries.add(EntryData(
                        id = obj.getInt("id"),
                        time = obj.getString("time"),
                        mood = obj.getString("mood"),
                        symptoms = obj.getString("symptoms"),
                    ))
                }
            } catch (_: Exception) {}
        }

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .cornerRadius(WidgetCornerRadius)
                .background(ColorProvider(backgroundColor))
                .clickable(onClick = actionStartActivity<MainActivity>(context))
                .padding(WidgetPadding),
        ) {
            // Header row: "Today" title + "+" button
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Today",
                    style = TextStyle(
                        color = ColorProvider(WidgetTealPrimary),
                        fontSize = WidgetHeaderFontSize,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                Box(
                    modifier = GlanceModifier
                        .size(WidgetAddButtonSize)
                        .cornerRadius(WidgetAddButtonSize / 2)
                        .background(ColorProvider(WidgetTealPrimary))
                        .clickable(onClick = actionStartActivity<MainActivity>(
                            context,
                            Uri.parse("wellnot://newentry"),
                        )),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "+",
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontSize = WidgetAddButtonFontSize,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center,
                        ),
                    )
                }
            }

            Spacer(modifier = GlanceModifier.height(WidgetHeaderBottomSpacing))

            if (entries.isEmpty()) {
                Text(
                    text = "No entries logged today",
                    style = TextStyle(
                        color = ColorProvider(WidgetSubtleGray),
                        fontSize = WidgetContentFontSize,
                    ),
                )
            } else {
                LazyColumn {
                    items(entries) { entry ->
                        Row(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .padding(vertical = WidgetEntryVerticalPadding)
                                .clickable(onClick = actionStartActivity<MainActivity>(
                                    context,
                                    Uri.parse("wellnot://entry/${entry.id}"),
                                )),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = entry.time,
                                style = TextStyle(
                                    color = ColorProvider(onSurfaceColor),
                                    fontSize = WidgetTimeFontSize,
                                ),
                            )
                            Spacer(modifier = GlanceModifier.width(WidgetEntryHorizontalSpacing))
                            Text(
                                text = if (entry.symptoms.isNotEmpty()) {
                                    "${entry.mood} - ${entry.symptoms}"
                                } else {
                                    entry.mood
                                },
                                style = TextStyle(
                                    color = ColorProvider(onSurfaceColor),
                                    fontSize = WidgetContentFontSize,
                                ),
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }
    }

    private data class EntryData(
        val id: Int,
        val time: String,
        val mood: String,
        val symptoms: String,
    )
}

class TodayMoodsReceiver : HomeWidgetGlanceWidgetReceiver<TodayMoodsWidget>() {
    override val glanceAppWidget = TodayMoodsWidget()
}
