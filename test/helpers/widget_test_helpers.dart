import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:symptom_tracker_app/services/database.dart';

/// Pumps a [widget] wrapped in [MaterialApp] + [Provider<AppDatabase>].
///
/// All screens obtain the database via `context.read<AppDatabase>()`, so this
/// helper mirrors the production widget tree set up in main.dart.
///
/// Cross-ref: production Provider setup is in lib/main.dart.
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget widget,
  required AppDatabase database,
}) async {
  await tester.pumpWidget(
    Provider<AppDatabase>(
      create: (_) => database,
      child: MaterialApp(
        home: widget,
      ),
    ),
  );
}
