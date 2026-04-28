package dev.alexo.symptom_tracker_app.glance

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
/// SharedPreferences name used by the home_widget package to store widget data.
/// Must match HomeWidgetPlugin.PREFERENCES (which is internal).
private const val HOME_WIDGET_PREFERENCES = "HomeWidgetPreferences"

/// Widget configuration activity shown when a user first places the widget.
/// Shows a preview of the widget and lets the user pick a theme (light/dark/system).
class WidgetConfigActivity : ComponentActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Default result is CANCELED — if the user backs out, the widget
        // is not placed.
        setResult(Activity.RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContent {
            MaterialTheme(
                colorScheme = MaterialTheme.colorScheme.copy(
                    primary = WidgetTealPrimary,
                )
            ) {
                ConfigScreen(onConfirm = { selectedTheme ->
                    saveThemeAndFinish(selectedTheme)
                })
            }
        }
    }

    private fun saveThemeAndFinish(theme: String) {
        // Write the theme preference to the home_widget SharedPreferences
        // so the Glance widget can read it.
        val prefs = getSharedPreferences(
            HOME_WIDGET_PREFERENCES,
            Context.MODE_PRIVATE,
        )
        prefs.edit().putString(WidgetThemeKey, theme).apply()

        val resultValue = Intent().putExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            appWidgetId,
        )
        setResult(Activity.RESULT_OK, resultValue)
        finish()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ConfigScreen(onConfirm: (String) -> Unit) {
    val selectedTheme = remember { mutableStateOf(WidgetThemeSystem) }
    val themeOptions = listOf(
        WidgetThemeLight to "Light",
        WidgetThemeDark to "Dark",
        WidgetThemeSystem to "System",
    )
    val isDark = selectedTheme.value == WidgetThemeDark
    val previewBg = if (isDark) WidgetDarkBackground else WidgetLightBackground
    val previewText = if (isDark) WidgetDarkOnSurface else WidgetLightOnSurface

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Widget settings") },
                actions = {
                    IconButton(onClick = { onConfirm(selectedTheme.value) }) {
                        Icon(Icons.Default.Check, contentDescription = "Confirm")
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(
                    horizontal = ConfigHorizontalPadding,
                    vertical = ConfigVerticalPadding,
                ),
        ) {
            // Live preview card that updates with theme selection
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(WidgetCornerRadius),
                colors = CardDefaults.cardColors(containerColor = previewBg),
                elevation = CardDefaults.cardElevation(
                    defaultElevation = ConfigCardElevation,
                ),
            ) {
                Column(modifier = Modifier.padding(WidgetPadding)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = "Today",
                            color = WidgetTealPrimary,
                            fontSize = WidgetHeaderFontSize,
                            fontWeight = FontWeight.Bold,
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Box(
                            modifier = Modifier
                                .size(WidgetAddButtonSize)
                                .clip(CircleShape)
                                .background(WidgetTealPrimary),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                Icons.Default.Add,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(ConfigAddIconSize),
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(ConfigPreviewHeaderSpacing))

                    SampleEntryRow("9:30 AM", "\uD83D\uDE0A - Headache, Fatigue", previewText)
                    Spacer(modifier = Modifier.height(ConfigSampleEntrySpacing))
                    SampleEntryRow("2:15 PM", "\uD83D\uDE10 - Nausea", previewText)
                }
            }

            Spacer(modifier = Modifier.height(ConfigDescriptionSpacing))

            // Theme picker
            Text(
                text = "Theme",
                style = MaterialTheme.typography.titleSmall,
            )
            Spacer(modifier = Modifier.height(ConfigSampleEntrySpacing))
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                themeOptions.forEachIndexed { index, (value, label) ->
                    SegmentedButton(
                        selected = selectedTheme.value == value,
                        onClick = { selectedTheme.value = value },
                        shape = SegmentedButtonDefaults.itemShape(
                            index = index,
                            count = themeOptions.size,
                        ),
                    ) {
                        Text(label)
                    }
                }
            }

            Spacer(modifier = Modifier.height(ConfigDescriptionSpacing))

            Text(
                text = "Your logged moods for today will appear in this widget. " +
                        "Tap an entry to view details, or tap + to log a new one.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun SampleEntryRow(time: String, content: String, textColor: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = time,
            fontSize = WidgetTimeFontSize,
            color = textColor,
        )
        Spacer(modifier = Modifier.width(WidgetEntryHorizontalSpacing))
        Text(
            text = content,
            fontSize = WidgetContentFontSize,
            color = textColor,
        )
    }
}
