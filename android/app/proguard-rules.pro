# R8 runs on release builds but not debug, which is why the QR scanner fails
# only in release: ML Kit's barcode entry points get stripped and the native
# side throws, which mobile_scanner surfaces as "An unexpected error occurred."
#
# mobile_scanner ships its own consumer rules, but they use a single wildcard
# (`com.google.mlkit.*`), which matches only classes sitting directly in that
# package — not `com.google.mlkit.vision.barcode`, where BarcodeScanning and
# BarcodeScannerOptions live. A double wildcard covers the subpackages.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Native barcode reader backing the bundled model.
-keep class com.google.android.libraries.barhopper.** { *; }

# CameraX resolves implementation classes by name at runtime.
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
