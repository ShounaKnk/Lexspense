import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SEC-06: Prevent screen capture and recents snapshot data leaks on Android
  if (Platform.isAndroid) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  // Initialize the database early so the first screen load is fast.
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: LexspenseApp()));
}
