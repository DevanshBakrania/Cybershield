package com.example.csh // ⚠️ Make sure this matches your actual package name!

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import android.net.wifi.WifiManager
import android.telephony.TelephonyManager
import android.view.WindowManager
import android.util.DisplayMetrics

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.cybershield/hardware"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeepMemoryInfo" -> result.success(getDeepMemoryInfo())
                "getDeepCpuInfo" -> result.success(getDeepCpuInfo())
                "getDesignCapacity" -> result.success(getDesignCapacity(this@MainActivity))
                "getLiveBatteryHardware" -> result.success(getLiveBatteryHardware(this@MainActivity))
                "getDeepNetworkInfo" -> result.success(getDeepNetworkInfo(this@MainActivity))
                "getDeepDisplayInfo" -> result.success(getDeepDisplayInfo(this@MainActivity))
                "getDeepCameraInfo" -> result.success(getDeepCameraInfo(this@MainActivity))
                "getDeepStorageInfo" -> result.success(getDeepStorageInfo())
                "getDeepOsInfo" -> result.success(getDeepOsInfo())
                "getAppCounts" -> result.success(getAppCounts(this@MainActivity))

                "getWidgetRealData" -> {
                    try {
                        // 1. Get Real Storage Data
                        val path = android.os.Environment.getDataDirectory()
                        val stat = android.os.StatFs(path.path)
                        val blockSize = stat.blockSizeLong
                        val totalBlocks = stat.blockCountLong
                        val availableBlocks = stat.availableBlocksLong

                        val totalStorage = totalBlocks * blockSize
                        val freeStorage = availableBlocks * blockSize
                        val usedStorage = totalStorage - freeStorage

                        // 2. Get Real Network Data Since Boot
                        val rxBytes = android.net.TrafficStats.getTotalRxBytes()
                        val txBytes = android.net.TrafficStats.getTotalTxBytes()
                        val totalNetwork = if (rxBytes == android.net.TrafficStats.UNSUPPORTED.toLong()) 0L else (rxBytes + txBytes)

                        // 3. Get Real Uptime
                        val uptimeMillis = android.os.SystemClock.elapsedRealtime()

                        // 4. Get Actual Device Model
                        val model = android.os.Build.MODEL

                        // Pack it all up and send to Flutter!
                        val data = mapOf(
                            "totalStorage" to totalStorage,
                            "usedStorage" to usedStorage,
                            "networkBytes" to totalNetwork,
                            "uptimeMillis" to uptimeMillis,
                            "model" to model
                        )
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("WIDGET_DATA_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // 1. LINUX KERNEL MEMORY PARSER (/proc/meminfo)
    private fun getDeepMemoryInfo(): Map<String, Long> {
        val memInfo = mutableMapOf<String, Long>()
        try {
            File("/proc/meminfo").forEachLine { line ->
                val parts = line.split("\\s+".toRegex())
                if (parts.size >= 2) {
                    val key = parts[0].replace(":", "")
                    val value = parts[1].toLongOrNull() ?: 0L
                    // Convert kB to Bytes
                    memInfo[key] = value * 1024L
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return memInfo
    }

    private fun getDeepCpuInfo(): Map<String, Any> {
        val cpuInfo = mutableMapOf<String, Any>()
        val numCores = Runtime.getRuntime().availableProcessors()

        cpuInfo["coreCount"] = numCores
        cpuInfo["hardware"] = android.os.Build.HARDWARE
        cpuInfo["architecture"] = System.getProperty("os.arch") ?: android.os.Build.SUPPORTED_ABIS[0]

        val currentFreqs = mutableListOf<Int>()
        val maxFreqs = mutableListOf<Int>()
        val governors = mutableListOf<String>()

        for (i in 0 until numCores) {
            // 1. Fetch Max Frequency
            try {
                val max = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq").readText().trim().toInt()
                maxFreqs.add(max)
            } catch (e: Exception) {
                maxFreqs.add(-1)
            }

            // 2. Fetch Live Frequency (Will test OEM SELinux policies)
            try {
                val cur = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq").readText().trim().toInt()
                currentFreqs.add(cur)
            } catch (e: Exception) {
                currentFreqs.add(-1)
            }

            // 3. Fetch CPU Governor
            try {
                val gov = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor").readText().trim()
                governors.add(gov)
            } catch (e: Exception) {
                governors.add("Restricted")
            }
        }

        // 4. Hunt for CPU Thermal Sensors
        var cpuTemp = "Unknown"
        try {
            val tzDirs = java.io.File("/sys/class/thermal/").listFiles()
            if (tzDirs != null) {
                for (dir in tzDirs) {
                    if (dir.name.startsWith("thermal_zone")) {
                        val type = java.io.File(dir, "type").readText().trim().lowercase()
                        if (type.contains("cpu") || type.contains("soc") || type.contains("tsens") || type.contains("mtktsc")) {
                            val temp = java.io.File(dir, "temp").readText().trim().toInt()
                            cpuTemp = if (temp > 1000) "${temp / 1000}°C" else "${temp}°C"
                            break
                        }
                    }
                }
            }
        } catch (e: Exception) {}

        cpuInfo["currentFreqs"] = currentFreqs
        cpuInfo["maxFreqs"] = maxFreqs
        cpuInfo["governors"] = governors
        cpuInfo["cpuTemp"] = cpuTemp

        return cpuInfo
    }

    // 3. JAVA REFLECTION: HIDDEN BATTERY CAPACITY
    private fun getDesignCapacity(context: Context): Double {
        var capacity = 0.0
        try {
            val powerProfileClass = Class.forName("com.android.internal.os.PowerProfile")
            val powerProfile = powerProfileClass.getConstructor(Context::class.java).newInstance(context)
            capacity = powerProfileClass.getMethod("getBatteryCapacity").invoke(powerProfile) as Double
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return capacity
    }

    // 4. LIVE BATTERY HARDWARE PULL
    private fun getLiveBatteryHardware(context: Context): Map<String, Any> {
        val batteryInfo = mutableMapOf<String, Any>()
        try {
            val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val intent = context.registerReceiver(null, intentFilter)

            if (intent != null) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                batteryInfo["level"] = if (level != -1 && scale != -1) (level * 100 / scale.toFloat()).toInt() else 0

                val temp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
                batteryInfo["temperature"] = if (temp > 0) temp / 10.0 else -1.0

                val voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
                batteryInfo["voltage"] = if (voltage > 1000) voltage / 1000.0 else voltage.toDouble()

                // ✨ FIXED: ACTUALLY GRABBING TECHNOLOGY NOW
                val tech = intent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
                batteryInfo["technology"] = if (tech.isNullOrEmpty()) "Unknown" else tech

                val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
                val pluggedStr = when (plugged) {
                    BatteryManager.BATTERY_PLUGGED_AC -> " (AC)"
                    BatteryManager.BATTERY_PLUGGED_USB -> " (USB)"
                    BatteryManager.BATTERY_PLUGGED_WIRELESS -> " (Wireless)"
                    else -> ""
                }

                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                batteryInfo["status"] = when (status) {
                    BatteryManager.BATTERY_STATUS_CHARGING -> "Charging$pluggedStr"
                    BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
                    BatteryManager.BATTERY_STATUS_FULL -> "Full$pluggedStr"
                    BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging$pluggedStr"
                    else -> "Unknown"
                }

                val health = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
                batteryInfo["health"] = when (health) {
                    BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
                    BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
                    BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
                    BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
                    BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
                    else -> "Unknown"
                }
            }

            val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            var currentMicroAmps = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)

            if (currentMicroAmps == 0) {
                try {
                    val sysFile = java.io.File("/sys/class/power_supply/battery/current_now")
                    if (sysFile.exists()) currentMicroAmps = sysFile.readText().trim().toInt()
                } catch (e: Exception) {}
            }

            val currentMa = currentMicroAmps / 1000
            batteryInfo["current"] = currentMa
            batteryInfo["current_mA"] = Math.abs(currentMa)

            var designCapacity = 0.0
            try {
                val powerProfileClass = Class.forName("com.android.internal.os.PowerProfile")
                val powerProfile = powerProfileClass.getConstructor(Context::class.java).newInstance(context)
                designCapacity = powerProfileClass.getMethod("getBatteryCapacity").invoke(powerProfile) as Double
            } catch (e: Exception) {}
            batteryInfo["designCapacity"] = designCapacity

        } catch (e: Exception) {
            batteryInfo["status"] = "Kotlin Exception"
        }
        return batteryInfo
    }

    // 5. DEEP NETWORK INFO (Wi-Fi & Cellular Dual IPs)
    private fun getDeepNetworkInfo(context: Context): Map<String, Any> {
        val netInfo = mutableMapOf<String, Any>()
        try {
            // --- 1. Wi-Fi Data ---
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            val wifiInfo = wifiManager.connectionInfo
            netInfo["ssid"] = wifiInfo.ssid?.replace("\"", "") ?: "Unknown"
            netInfo["linkSpeed"] = wifiInfo.linkSpeed
            netInfo["rssi"] = wifiInfo.rssi

            // ✨ SEPARATED WI-FI IP
            val ip = wifiInfo.ipAddress
            netInfo["wifi_ip"] = if (ip != 0) String.format("%d.%d.%d.%d", (ip and 0xff), (ip shr 8 and 0xff), (ip shr 16 and 0xff), (ip shr 24 and 0xff)) else "Disconnected"

            // ✨ UPDATED: SEPARATE CELLULAR IP SCANNER (Ignores dummy interfaces)
            var cellIp = "Disconnected"
            try {
                val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
                for (intf in interfaces) {
                    val name = intf.name.lowercase()

                    // Ignore Wi-Fi, loopback, and useless virtual dummy interfaces
                    if (name.contains("wlan") || name.contains("lo") || name.contains("dummy") || name.contains("p2p")) continue

                    for (enumIpAddr in intf.inetAddresses) {
                        if (!enumIpAddr.isLoopbackAddress && enumIpAddr is java.net.Inet4Address) {
                            val ipStr = enumIpAddr.hostAddress
                            if (!ipStr.isNullOrEmpty()) {
                                cellIp = ipStr
                                break // ✨ We found the real IP! Stop the inner loop.
                            }
                        }
                    }
                    if (cellIp != "Disconnected") break // ✨ Stop checking other antennas!
                }
            } catch (ex: Exception) { }
            netInfo["cellular_ip"] = cellIp

            // --- 2. Mobile Network Data ---
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
            netInfo["phoneType"] = when (telephonyManager.phoneType) {
                android.telephony.TelephonyManager.PHONE_TYPE_GSM -> "GSM"
                android.telephony.TelephonyManager.PHONE_TYPE_CDMA -> "CDMA"
                android.telephony.TelephonyManager.PHONE_TYPE_SIP -> "SIP"
                else -> "None"
            }

            netInfo["mobileDataStatus"] = when (telephonyManager.dataState) {
                android.telephony.TelephonyManager.DATA_DISCONNECTED -> "Disconnected"
                android.telephony.TelephonyManager.DATA_CONNECTING -> "Connecting..."
                android.telephony.TelephonyManager.DATA_CONNECTED -> "Connected"
                android.telephony.TelephonyManager.DATA_SUSPENDED -> "Suspended"
                else -> "Unknown"
            }

            netInfo["operator"] = telephonyManager.simOperatorName.ifEmpty { telephonyManager.networkOperatorName ?: "Unknown" }
            netInfo["simState"] = when (telephonyManager.simState) {
                android.telephony.TelephonyManager.SIM_STATE_READY -> "Ready"
                android.telephony.TelephonyManager.SIM_STATE_ABSENT -> "Absent"
                else -> "Unknown"
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return netInfo
    }

    // 6. DEEP DISPLAY INFO
    private fun getDeepDisplayInfo(context: Context): Map<String, Any> {
        val displayInfo = mutableMapOf<String, Any>()

        try {
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val display = windowManager.defaultDisplay
            val metrics = DisplayMetrics()
            val realMetrics = DisplayMetrics()

            display.getMetrics(metrics)
            display.getRealMetrics(realMetrics)

            displayInfo["logicalWidth"] = metrics.widthPixels
            displayInfo["logicalHeight"] = metrics.heightPixels
            displayInfo["physicalWidth"] = realMetrics.widthPixels
            displayInfo["physicalHeight"] = realMetrics.heightPixels

            // ✨ THE FIX: Get exact X and Y hardware pixels per inch
            displayInfo["exactPpiX"] = realMetrics.xdpi
            displayInfo["exactPpiY"] = realMetrics.ydpi

            // Average them out for the main readout (matches DevCheck)
            displayInfo["averagePpi"] = ((realMetrics.xdpi + realMetrics.ydpi) / 2.0)

            displayInfo["densityDpi"] = metrics.densityDpi // Keep logical for software reference
            displayInfo["refreshRate"] = display.refreshRate

            val xInches = realMetrics.widthPixels.toDouble() / realMetrics.xdpi
            val yInches = realMetrics.heightPixels.toDouble() / realMetrics.ydpi
            val screenInches = Math.sqrt(xInches * xInches + yInches * yInches)
            displayInfo["screenInches"] = screenInches

        } catch (e: Exception) {
            e.printStackTrace()
        }

        return displayInfo
    }

    // 7. DEEP CAMERA HARDWARE
    private fun getDeepCameraInfo(context: Context): List<Map<String, Any>> {
        val cameraList = mutableListOf<Map<String, Any>>()
        try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
            for (cameraId in manager.cameraIdList) {
                val characteristics = manager.getCameraCharacteristics(cameraId)
                val cameraInfo = mutableMapOf<String, Any>()

                val facing = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING)
                cameraInfo["facing"] = when (facing) {
                    android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT -> "Front Camera"
                    android.hardware.camera2.CameraCharacteristics.LENS_FACING_BACK -> "Rear Camera"
                    android.hardware.camera2.CameraCharacteristics.LENS_FACING_EXTERNAL -> "External Camera"
                    else -> "Unknown Camera"
                }

                val size = characteristics.get(android.hardware.camera2.CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE)
                if (size != null) {
                    val mp = (size.width * size.height) / 1000000.0
                    cameraInfo["megapixels"] = String.format("%.1f MP", mp)
                    cameraInfo["resolution"] = "${size.width} x ${size.height}"
                } else {
                    cameraInfo["megapixels"] = "Unknown"
                    cameraInfo["resolution"] = "Unknown"
                }

                val apertures = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)
                cameraInfo["apertures"] = apertures?.joinToString(", ") { "f/$it" } ?: "Fixed"

                val focalLengths = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                cameraInfo["focalLengths"] = focalLengths?.joinToString(", ") { "${it}mm" } ?: "Unknown"

                cameraList.add(cameraInfo)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return cameraList
    }

    // 8. DEEP STORAGE INFO (StatFs Partitions)
    private fun getDeepStorageInfo(): Map<String, Any> {
        val storageInfo = mutableMapOf<String, Any>()
        try {
            // 1. User Data Partition (/data)
            val dataPath = android.os.Environment.getDataDirectory().path
            val dataStat = android.os.StatFs(dataPath)
            val dataBlockSize = dataStat.blockSizeLong
            val dataTotalBlocks = dataStat.blockCountLong
            val dataAvailableBlocks = dataStat.availableBlocksLong

            val dataTotalBytes = dataTotalBlocks * dataBlockSize
            val dataFreeBytes = dataAvailableBlocks * dataBlockSize
            val dataUsedBytes = dataTotalBytes - dataFreeBytes

            // 2. System OS Partition (/system or /root)
            val rootPath = android.os.Environment.getRootDirectory().path
            val rootStat = android.os.StatFs(rootPath)
            val rootBlockSize = rootStat.blockSizeLong
            val rootTotalBlocks = rootStat.blockCountLong
            val rootAvailableBlocks = rootStat.availableBlocksLong

            val rootTotalBytes = rootTotalBlocks * rootBlockSize
            val rootFreeBytes = rootAvailableBlocks * rootBlockSize
            val rootUsedBytes = rootTotalBytes - rootFreeBytes

            storageInfo["dataTotal"] = dataTotalBytes
            storageInfo["dataUsed"] = dataUsedBytes
            storageInfo["dataFree"] = dataFreeBytes

            storageInfo["systemTotal"] = rootTotalBytes
            storageInfo["systemUsed"] = rootUsedBytes
            storageInfo["systemFree"] = rootFreeBytes

        } catch (e: Exception) {
            e.printStackTrace()
        }
        return storageInfo
    }

    // 9. DEEP OS INFO (Kernel, SELinux, OxygenOS Build)
    private fun getDeepOsInfo(): Map<String, Any> {
        val osInfo = mutableMapOf<String, Any>()

        // Isolate standard APIs so a single SecurityException doesn't break everything
        try { osInfo["androidVersion"] = android.os.Build.VERSION.RELEASE } catch (e: Exception) {}
        try { osInfo["sdkInt"] = android.os.Build.VERSION.SDK_INT } catch (e: Exception) {}
        try { osInfo["securityPatch"] = if (android.os.Build.VERSION.SDK_INT >= 23) android.os.Build.VERSION.SECURITY_PATCH else "Unknown" } catch (e: Exception) {}

        // This is the culprit! We catch the security exception specifically here.
        try {
            osInfo["baseband"] = android.os.Build.getRadioVersion() ?: "Unknown"
        } catch (e: Exception) {
            osInfo["baseband"] = "Restricted by OS"
        }

        // 1. Linux Kernel Version (/proc/version)
        try {
            val rawKernel = java.io.File("/proc/version").readText().trim()
            val match = Regex("Linux version ([^\\s]+)").find(rawKernel)
            osInfo["kernel"] = match?.groupValues?.get(1) ?: System.getProperty("os.version") ?: "Unknown"
        } catch (e: Exception) {
            osInfo["kernel"] = System.getProperty("os.version") ?: "Unknown"
        }

        // 2. SELinux Status Verification
        try {
            val process = Runtime.getRuntime().exec("getenforce")
            val reader = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
            osInfo["selinux"] = reader.readLine()?.trim() ?: "Unknown"
        } catch (e: Exception) {
            // If the system blocks execution, SELinux is actively enforcing
            osInfo["selinux"] = "Enforcing"
        }

        // 3. Exact OEM Build, Slot, and Instruction Sets
        try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get = systemProperties.getMethod("get", String::class.java, String::class.java)

            osInfo["oemBuild"] = get.invoke(null, "ro.build.display.id", "Unknown") as String

            // ✨ Get Active Slot (e.g., _a or _b)
            osInfo["activeSlot"] = get.invoke(null, "ro.boot.slot_suffix", "") as String
        } catch (e: Exception) {
            osInfo["oemBuild"] = android.os.Build.DISPLAY
            osInfo["activeSlot"] = ""
        }

        // ✨ Get Instruction Sets (e.g., arm64-v8a armeabi-v7a)
        osInfo["instructionSets"] = android.os.Build.SUPPORTED_ABIS.joinToString(" ")

        return osInfo
    }

    // 10. TRUE INSTALLED APPS COUNT (Matches DevCheck Logic)
    private fun getAppCounts(context: Context): Map<String, Int> {
        var userApps = 0
        var sysApps = 0
        try {
            val pm = context.packageManager
            val packages = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA)

            for (appInfo in packages) {
                val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0 ||
                        (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                if (!isSystem) {
                    // DevCheck includes ALL user apps (Exactly 65)
                    userApps++
                } else {
                    // DevCheck ONLY includes system apps if they have a launch icon (~33 out of 365)
                    val hasLaunchIntent = pm.getLaunchIntentForPackage(appInfo.packageName) != null
                    if (hasLaunchIntent) {
                        sysApps++
                    }
                }
            }
        } catch (e: Exception) { }
        return mapOf("userApps" to userApps, "systemApps" to sysApps)
    }
}