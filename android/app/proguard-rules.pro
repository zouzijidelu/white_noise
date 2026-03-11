# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

-dontoptimize

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
-renamesourcefileattribute SourceFile

-keepclassmembers enum * {*;}

#-----------------------------------------GsonBean------------------------------------------------#
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# for reflectMethod
-keepattributes EnclosingMethod
# Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

#------------------------------------------------AppsFlyer-------------------------------------------------#
-keep class com.appsflyer.** { *; }
-keep public class com.android.installreferrer.** { *; }

-keepclassmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# HTTP Client (http package)
-keep class io.netty.** { *; }
-keep class org.apache.** { *; }
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.google.gson.** { *; }

-keep class com.italkbbtv.phone.HXApplication
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service
-obfuscationdictionary dictionary-drakeet.txt
-classobfuscationdictionary dictionary-drakeet.txt
-packageobfuscationdictionary dictionary-drakeet.txt

# audio_service package
-keep class com.ryanheise.audioservice.** { *; }
-keep class * extends com.ryanheise.audioservice.BaseAudioHandler { *; }
