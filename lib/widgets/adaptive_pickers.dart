// adaptive_pickers.dart: Platform-adaptive date and time pickers.
//
// On iOS, shows Cupertino-style spinning wheel pickers in a modal bottom sheet.
// On Android, shows standard Material Design pickers.
//
// Cross-ref:
//   - Used by screens/entry_screen.dart (date/time selection for entries)
//   - Used by screens/manage_items_screen.dart (notification time picker)
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:symptom_tracker_app/constants/layout.dart';

/// Shows a platform-adaptive time picker.
///
/// On iOS, displays a Cupertino spinning wheel in a bottom sheet.
/// On Android, displays the standard Material time picker dialog.
/// Returns the selected [TimeOfDay], or null if cancelled.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  if (Platform.isIOS) {
    return _showCupertinoTimePicker(context: context, initialTime: initialTime);
  }
  return showTimePicker(context: context, initialTime: initialTime);
}

/// Shows a platform-adaptive date picker.
///
/// On iOS, displays a Cupertino spinning wheel in a bottom sheet.
/// On Android, displays the standard Material date picker dialog.
/// Returns the selected [DateTime], or null if cancelled.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  if (Platform.isIOS) {
    return _showCupertinoDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

/// iOS Cupertino time picker shown as a modal bottom sheet.
Future<TimeOfDay?> _showCupertinoTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  TimeOfDay? result;
  final initialDateTime = DateTime(
    2000,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      var selectedTime = initialDateTime;
      return Container(
        height: cupertinoPickerSheetHeight,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Top bar with Cancel and Done buttons — no fixed height so
            // buttons size intrinsically and adapt to text scaling.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    result = TimeOfDay(
                      hour: selectedTime.hour,
                      minute: selectedTime.minute,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            // Spinning wheel time picker.
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dateTime) {
                  selectedTime = dateTime;
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  return result;
}

/// iOS Cupertino date picker shown as a modal bottom sheet.
Future<DateTime?> _showCupertinoDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime? result;

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      var selectedDate = initialDate;
      return Container(
        height: cupertinoPickerSheetHeight,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Top bar with Cancel and Done buttons — no fixed height so
            // buttons size intrinsically and adapt to text scaling.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    result = selectedDate;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            // Spinning wheel date picker.
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (dateTime) {
                  selectedDate = dateTime;
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  return result;
}
