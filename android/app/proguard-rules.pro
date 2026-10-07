-keep class com.jcraft.**  { *; }
-keep class io.flutter.util.PathUtils { *; }

# Room's generated database classes, which WorkManager reaches reflectively.
#
# `androidx.work:work-runtime-ktx` (the CF alert scheduler) brings in Room, and
# Room instantiates its generated `<Name>_Impl` through
# `getDeclaredConstructor().newInstance()` rather than by name — so R8 sees a
# constructor nothing calls and strips it. The class survives on Room's own
# `-keep class * extends androidx.room.RoomDatabase` rule, which keeps the name
# but not the members, and the app then dies before any Dart runs:
#
#   java.lang.RuntimeException: Unable to get provider
#     androidx.startup.InitializationProvider
#   Caused by: java.lang.NoSuchMethodException:
#     androidx.work.impl.WorkDatabase_Impl.<init> []
#
# Keeping the constructor is what the reflective call needs; keeping every
# member of the generated classes is what makes that safe across Room versions.
-keep class * extends androidx.room.RoomDatabase { *; }
