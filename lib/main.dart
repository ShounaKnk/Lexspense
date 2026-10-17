import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database early so the first screen load is fast.
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: LexspenseApp()));
}
