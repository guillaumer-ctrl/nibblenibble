# Firebase (Auth, Firestore, Crashlytics) uses reflection for some internal
# model classes; keep everything under com.google.firebase and the gRPC/
# protobuf classes Firestore's wire layer depends on.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Mobile Ads (AdMob) loads ad format classes by name.
-keep class com.google.android.gms.ads.** { *; }
-keep public class com.google.android.gms.ads.mediation.** { *; }

# Play Core split-install classes referenced by Flutter's deferred-components
# support, even though this app doesn't use deferred components.
-dontwarn com.google.android.play.core.**

# WorkManager (pulled in transitively, e.g. by AdMob) initializes a Room
# database via reflection (Class.forName on a generated "*_Impl" class)
# through androidx.startup.InitializationProvider at app startup — if R8
# renames or strips that generated class, the lookup fails and the app
# crashes on launch before any Dart code runs ("Failed to create an
# instance of androidx.work.impl.WorkDatabase"). Keep WorkManager/Room's
# generated code intact rather than trying to enumerate every generated name.
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**
