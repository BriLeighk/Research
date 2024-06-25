package com.example.spyware

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Base64
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "samples.flutter.dev/spyware"
        private const val SETTINGS_CHANNEL = "com.example.spyware/settings"
        private const val PRIVACY_CHANNEL = "com.example.spyware/privacy"
        private const val APP_CHECK_CHANNEL = "com.example.spyware/app_check"
        private const val APP_DETAILS_CHANNEL = "com.example.spyware/app_details"
        private const val APP_LAUNCH_CHANNEL = "com.example.spyware/app_launch"
        private const val ADB_CHANNEL = "com.example.spyware/adb"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSpywareApps" -> {
                        val spywareApps = getDetectedSpywareApps()
                        if (spywareApps != null) {
                            result.success(spywareApps)
                        } else {
                            result.error("UNAVAILABLE", "Error retrieving list of apps from the device.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAppSettings" -> {
                        val packageName = call.argument<String>("package")
                        if (packageName != null) {
                            openAppSettings(packageName)
                            result.success(null)
                        } else {
                            result.error("ERROR", "No package name provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIVACY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchPrivacyCheckup" -> {
                        launchPrivacyCheckup()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHECK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAppInstalled" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val isInstalled = isAppInstalled(packageName)
                            result.success(isInstalled)
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_DETAILS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppDetails" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val appDetails = getAppDetails(packageName)
                            result.success(appDetails)
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADB_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanOtherDevice" -> {
                    val connectedDevices = getConnectedDevices()
                    if (connectedDevices.isNotEmpty()) {
                        val scanResult = scanDevice(connectedDevices.first())
                        result.success(scanResult)
                    } else {
                        result.error("NO_DEVICE", "No connected device found.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // New method channel for launching apps
        
    }

    private fun getConnectedDevices(): List<String> {
        return try {
            val process = Runtime.getRuntime().exec("adb devices")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val devices = mutableListOf<String>()
            reader.forEachLine { line ->
                if (line.endsWith("device")) {
                    val deviceID = line.split("\t")[0]
                    devices.add(deviceID)
                }
            }
            reader.close()
            devices
        } catch (e: Exception) {
            Log.e("ADBError", "Error getting connected devices", e)
            emptyList()
        }
    }

    private fun scanDevice(deviceID: String): String {
        return try {
            val process = Runtime.getRuntime().exec("adb -s $deviceID shell pm list packages")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                output.append(line).append("\n")
            }
            reader.close()
            output.toString()
        } catch (e: Exception) {
            Log.e("ADBError", "Error scanning device $deviceID", e)
            "Error scanning device $deviceID: ${e.message}"
        }
    }


    private lateinit var spywareAppIds: Set<String>
    private lateinit var appTypes: Map<String, String>

    private fun loadSpywareData() {
        val ids = mutableSetOf<String>()
        val types = mutableMapOf<String, String>()
        try {
            assets.open("app-ids-research.csv").bufferedReader().use { reader ->
                reader.readLine()
                reader.forEachLine { line ->
                    line.split(",").let {
                        if (it.size > 2) {
                            ids.add(it[0].trim())
                            types[it[0].trim()] = it[2].trim()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("SpywareDetection", "Failed to read spyware IDs from CSV", e)
        }
        spywareAppIds = ids
        appTypes = types
    }

    private fun getDetectedSpywareApps(): List<Map<String, Any?>>? {
        if (!::spywareAppIds.isInitialized) {
            loadSpywareData()
        }

        val detectedSpywareApps = mutableListOf<Map<String, Any?>>()
        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        installedApps.parallelStream().forEach { app ->
            val appID = app.packageName
            Log.e("AppID", "Check App ID: $appID")
            if (appID in spywareAppIds) {
                val appName = app.loadLabel(packageManager).toString()
                val iconBase64 = getBase64IconFromDrawable(app.loadIcon(packageManager))
                val installer = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    val installSourceInfo = packageManager.getInstallSourceInfo(appID)
                    installSourceInfo.installingPackageName ?: "Unknown"
                } else {
                    packageManager.getInstallerPackageName(appID) ?: "Unknown"
                }
                val storeLink = getStoreLink(appID, installer)
                val appType = appTypes[appID] ?: "Unknown"
                val appInfo: Map<String, Any?> = mapOf(
                    "id" to appID,
                    "name" to appName,
                    "icon" to iconBase64,
                    "installer" to installer,
                    "storeLink" to storeLink,
                    "type" to appType
                )
                synchronized(detectedSpywareApps) {
                    detectedSpywareApps.add(appInfo)
                }
            }
        }
        return detectedSpywareApps
    }

    private fun getStoreLink(packageName: String, installer: String): String? {
        return when (installer) {
            "com.android.vending" -> "https://play.google.com/store/apps/details?id=$packageName"
            "com.amazon.venezia" -> "https://www.amazon.com/gp/mas/dl/android?p=$packageName"
            else -> null
        }
    }

    private fun getBase64IconFromDrawable(drawable: Drawable): String {
        val bitmap = (drawable as? BitmapDrawable)?.bitmap ?: Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888).also {
            val canvas = Canvas(it)
            drawable.setBounds(0, 0, drawable.intrinsicWidth, drawable.intrinsicHeight)
            drawable.draw(canvas)
        }
        ByteArrayOutputStream().also { baos ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
            return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
        }
    }

    private fun openAppSettings(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchPrivacyCheckup() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://myaccount.google.com/privacycheckup"))
        startActivity(intent)
    }
    

    private fun getAppDetails(packageName: String): Map<String, String>? {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val iconBase64 = getBase64IconFromDrawable(packageManager.getApplicationIcon(packageName))
            mapOf("name" to appName, "icon" to iconBase64, "package" to packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun openApp(packageName: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            startActivity(launchIntent)
        } else {
            Log.e("LaunchApp", "Unable to launch app: $packageName")
        }
    }

    private fun getAppPermissions(packageName: String): List<String> {
        val grantedPermissions = mutableListOf<String>()
        try {
            val permissions = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS).requestedPermissions
            if (permissions != null) {
                for (permission in permissions) {
                    if (packageManager.checkPermission(permission, packageName) == PackageManager.PERMISSION_GRANTED) {
                        grantedPermissions.add(permission)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("PermissionsError", "Error fetching permissions for $packageName", e)
        }
        return grantedPermissions
    }
}
