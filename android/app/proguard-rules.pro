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

# Suppress Play Store deferred component / split install warnings referenced by Flutter engine
-dontwarn com.google.android.play.core.**

# AndroidX Startup, WorkManager & Room rules (required by home_widget)
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.work.impl.**

# FilePicker plugin rules
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Printing plugin rules
-keep class net.nfet.flutter.printing.** { *; }

# Shared preferences plugin rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }

