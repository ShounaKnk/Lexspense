# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods for Flutter and plugins
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter WindowManager (SEC-06)
-keep class io.incepture.flutter_windowmanager.** { *; }

# HomeWidget plugin rules
-keep class es.antonborri.home_widget.** { *; }

# Sqflite plugin rules
-keep class com.tekartik.sqflite.** { *; }

# Keep line numbers for split debug info and symbolication
-keepattributes SourceFile,LineNumberTable
