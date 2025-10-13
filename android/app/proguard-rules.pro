# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Suppress warnings for missing ProGuard annotations (from missing_rules.txt)
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Razorpay specific rules
-keep class com.razorpay.AnalyticsEvent { *; }
-keep class com.razorpay.AnalyticsEvent$* { *; }

# Keep all classes with @Keep annotation
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}
-keep @proguard.annotation.KeepClassMembers class * { *; }
-keepclassmembers class * {
    @proguard.annotation.KeepClassMembers *;
}

# Razorpay WebView
-keepclassmembers class com.razorpay.RazorpayWebView$* { *; }
-keepclassmembers class com.razorpay.RazorpayWebView { *; }

# Razorpay Payment methods
-keep class com.razorpay.PaymentMethodsActivity { *; }
-keep class com.razorpay.PaymentMethodsActivity$* { *; }

# Razorpay Payment result
-keep class com.razorpay.PaymentResultListener { *; }
-keep class com.razorpay.PaymentResult { *; }

# Razorpay Checkout
-keep class com.razorpay.Checkout { *; }
-keep class com.razorpay.Checkout$* { *; }

# Razorpay Utils
-keep class com.razorpay.Utils { *; }
-keep class com.razorpay.Utils$* { *; }

# Razorpay Constants
-keep class com.razorpay.Constants { *; }
-keep class com.razorpay.Constants$* { *; }

# Razorpay Logger
-keep class com.razorpay.Logger { *; }
-keep class com.razorpay.Logger$* { *; }

# Razorpay Google Pay Integration
-keep class com.razorpay.RzpGpayMerged { *; }
-keep class com.razorpay.RzpGpayMerged$* { *; }

# Razorpay Network
-keep class com.razorpay.NetworkUtils { *; }
-keep class com.razorpay.NetworkUtils$* { *; }

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Suppress warnings for Flutter deferred components
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Services and Google Pay
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Suppress warnings for Google Play Services
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Gson (if used by Razorpay)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp (if used by Razorpay)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Retrofit (if used by Razorpay)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
