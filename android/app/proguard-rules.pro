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
