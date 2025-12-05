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

# Firebase - General
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Auth - Critical for login to work in release
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.auth.internal.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }
-dontwarn com.google.firebase.storage.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Google Sign-In - Critical for Google login
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.api.client.** { *; }
-keep class com.google.api.client.googleapis.** { *; }
-keep class com.google.api.client.http.** { *; }
-keep class com.google.api.client.json.** { *; }
-keep class com.google.api.client.util.** { *; }
-keep class com.google.api.services.** { *; }
-keep class com.google.auth.** { *; }
-keep class com.google.auth.oauth2.** { *; }
-dontwarn com.google.android.gms.auth.**
-dontwarn com.google.api.client.**
-dontwarn com.google.auth.**

# Google Sign-In Account classes
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keepclassmembers class * extends com.google.android.gms.common.api.Api {
    <init>(...);
}
-keepclassmembers class * implements com.google.android.gms.common.api.Api$ApiOptions$HasOptions {
    <init>(...);
}
-keepclassmembers class * implements com.google.android.gms.common.api.Api$ApiOptions$NotRequiredOptions {
    <init>(...);
}
-keepclassmembers class * implements com.google.android.gms.common.api.Api$ApiOptions$Optional {
    <init>(...);
}

# Keep Google Sign-In result classes
-keep class com.google.android.gms.auth.api.signin.GoogleSignInAccount { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInOptions { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInResult { *; }

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

# Phone Authentication (Firebase Phone Auth)
-keep class com.google.firebase.auth.PhoneAuthProvider.** { *; }
-keep class com.google.firebase.auth.PhoneAuthCredential { *; }
-keep class com.google.firebase.auth.PhoneAuthProvider$OnVerificationStateChangedCallbacks { *; }
-keepclassmembers class * extends com.google.firebase.auth.PhoneAuthProvider$OnVerificationStateChangedCallbacks {
    <init>(...);
}

# Keep Firebase User class
-keep class com.google.firebase.auth.FirebaseUser { *; }
-keep class com.google.firebase.auth.UserInfo { *; }
-keep class com.google.firebase.auth.AuthCredential { *; }
-keep class com.google.firebase.auth.AuthResult { *; }

# Keep Firebase Auth exceptions
-keep class com.google.firebase.auth.FirebaseAuthException { *; }
-keep class com.google.firebase.auth.FirebaseAuthInvalidCredentialsException { *; }
-keep class com.google.firebase.auth.FirebaseAuthInvalidUserException { *; }
-keep class com.google.firebase.auth.FirebaseAuthUserCollisionException { *; }
-keep class com.google.firebase.auth.FirebaseAuthWeakPasswordException { *; }

# Keep reflection-based classes used by Firebase
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep classes used by Flutter plugins for authentication
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.google_sign_in.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.storage.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-dontwarn io.flutter.plugins.**

# Keep SharedPreferences (used for storing auth state)
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# Keep classes that use reflection (common in Firebase)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep WebView classes (used by Google Sign-In)
-keep class android.webkit.** { *; }
-dontwarn android.webkit.**

# CRITICAL: SafetyNet for reCAPTCHA (required for phone auth)
-keep class com.google.android.gms.safetynet.** { *; }
-keep class com.google.android.recaptcha.** { *; }
-dontwarn com.google.android.gms.safetynet.**
-dontwarn com.google.android.recaptcha.**

# CRITICAL: Play Services Auth (Google Sign-In)
-keep class com.google.android.gms.auth.api.** { *; }
-keep class com.google.android.gms.auth.api.phone.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keepclassmembers class com.google.android.gms.auth.api.** { *; }

# CRITICAL: Firebase Auth internal classes
-keep class com.google.firebase.auth.internal.** { *; }
-keep class com.google.firebase.auth.api.** { *; }
-keepclassmembers class com.google.firebase.auth.internal.** { *; }

# CRITICAL: Keep all classes with GoogleSignIn
-keep class * extends com.google.android.gms.auth.api.signin.GoogleSignInAccount { *; }
-keep class * implements com.google.android.gms.auth.api.signin.** { *; }

# CRITICAL: Phone auth SMS retriever
-keep class com.google.android.gms.auth.api.phone.SmsRetriever { *; }
-keep class com.google.android.gms.auth.api.phone.SmsRetrieverClient { *; }

# CRITICAL: Keep all BuildConfig classes (used by Firebase and Google services)
-keep class **.BuildConfig { *; }

# CRITICAL: Prevent optimization that breaks reflection
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# CRITICAL: Keep SourceFile and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# CRITICAL: Keep all Firebase internal classes
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep enum com.google.firebase.** { *; }

# CRITICAL: Kotlin metadata (important for plugins)
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata { *; }

# CRITICAL: Android X Activity Result API (used by Google Sign-In)
-keep class androidx.activity.result.** { *; }
-keep class androidx.activity.result.contract.** { *; }

# CRITICAL: Keep all listeners and callbacks
-keep class * implements com.google.android.gms.tasks.OnCompleteListener { *; }
-keep class * implements com.google.android.gms.tasks.OnSuccessListener { *; }
-keep class * implements com.google.android.gms.tasks.OnFailureListener { *; }
-keep class * implements com.google.firebase.auth.PhoneAuthProvider$OnVerificationStateChangedCallbacks { *; }

# CRITICAL: Keep R8 annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault
