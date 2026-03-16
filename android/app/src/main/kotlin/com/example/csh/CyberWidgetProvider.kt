package com.example.csh // ⚠️ Make sure this matches your actual package name!

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.SystemClock
import android.widget.RemoteViews
import android.app.ActivityManager
import android.os.Environment
import android.os.StatFs
import android.net.TrafficStats
import java.net.NetworkInterface
import java.net.Inet4Address

class CyberWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    // ✨ 1. Start the silent background loop when the widget is dropped on the screen
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, CyberWidgetProvider::class.java).apply {
            action = "com.example.cs11.WIDGET_SYNC"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Android's battery-safe limit for background widgets is exactly 15 minutes
        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            pendingIntent
        )
    }

    // ✨ 2. Catch the background ping every 15 mins and refresh the hardware data
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.example.cs11.WIDGET_SYNC") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, CyberWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)

            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    // ✨ 3. Clean up the background loop to save battery when the widget is deleted
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, CyberWidgetProvider::class.java).apply {
            action = "com.example.cs11.WIDGET_SYNC"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // 1. Model & Uptime
            views.setTextViewText(R.id.wid_model, android.os.Build.MODEL)
            val uptimeMillis = SystemClock.elapsedRealtime()
            val hours = (uptimeMillis / (1000 * 60 * 60)).toInt()
            val mins = ((uptimeMillis / (1000 * 60)) % 60).toInt()
            views.setTextViewText(R.id.wid_uptime, "Uptime ${hours}h ${mins}m")

            // 2. RAM Usage
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            am.getMemoryInfo(memInfo)
            val ramPct = (((memInfo.totalMem - memInfo.availMem).toDouble() / memInfo.totalMem) * 100).toInt()
            views.setTextViewText(R.id.wid_ram_val, "$ramPct%")
            views.setProgressBar(R.id.wid_ram_bar, 100, ramPct, false)

            // 3. Storage Usage
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)
            val totalStorage = stat.blockCountLong * stat.blockSizeLong
            val freeStorage = stat.availableBlocksLong * stat.blockSizeLong
            val usedStorage = totalStorage - freeStorage
            val storagePct = if (totalStorage > 0) ((usedStorage.toDouble() / totalStorage) * 100).toInt() else 0
            views.setTextViewText(R.id.wid_storage_val, "$storagePct%")
            views.setProgressBar(R.id.wid_storage_bar, 100, storagePct, false)

            // 4. Battery & Temp
            val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
                context.applicationContext.registerReceiver(null, ifilter)
            }
            val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            val batPct = if (level != -1 && scale != -1) (level * 100 / scale.toFloat()).toInt() else 0

            val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
            val batTemp = if (temp > 0) temp / 10 else 0

            views.setTextViewText(R.id.wid_bat_val, "🔋 $batPct%")
            views.setTextViewText(R.id.wid_temp_val, "$batTemp°C")

            // 5. Network Data
            val rxBytes = TrafficStats.getTotalRxBytes()
            val txBytes = TrafficStats.getTotalTxBytes()
            val totalBytes = if (rxBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else (rxBytes + txBytes)
            val mb = totalBytes / (1024 * 1024)

            if (mb > 1024) {
                views.setTextViewText(R.id.wid_data_val, String.format("%.1f GB", mb / 1024.0))
            } else {
                views.setTextViewText(R.id.wid_data_val, "$mb MB")
            }

            // 6. Tap to Open App
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            // Tapping the widget opens the main Dashboard
            views.setOnClickPendingIntent(R.id.wid_model, pendingIntent)

            // Push the update to the screen!
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ THE CYBER STRIP (4x1)
// ─────────────────────────────────────────────────────────────────────────────
class CyberStripProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_cyber_strip)

            // Get RAM
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            am.getMemoryInfo(memInfo)
            val ramPct = (((memInfo.totalMem - memInfo.availMem).toDouble() / memInfo.totalMem) * 100).toInt()

            // Get Battery & Temp
            val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { context.applicationContext.registerReceiver(null, it) }
            val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            val batPct = if (level != -1 && scale != -1) (level * 100 / scale.toFloat()).toInt() else 0
            val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
            val batTemp = if (temp > 0) temp / 10 else 0

            views.setTextViewText(R.id.strip_ram_val, "$ramPct%")
            views.setTextViewText(R.id.strip_bat_val, "$batPct%")
            views.setTextViewText(R.id.strip_temp_val, "$batTemp°C")

            // ✨ MANUAL SYNC BUTTON LOGIC
            val syncIntent = Intent(context, CyberStripProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val pendingSync = PendingIntent.getBroadcast(context, appWidgetId, syncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_sync_strip, pendingSync)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ THE POWER NODE (2x2)
// ─────────────────────────────────────────────────────────────────────────────
class PowerNodeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_power_node)

            val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { context.applicationContext.registerReceiver(null, it) }
            val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            val batPct = if (level != -1 && scale != -1) (level * 100 / scale.toFloat()).toInt() else 0
            val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
            val batTemp = if (temp > 0) temp / 10 else 0

            views.setTextViewText(R.id.node_bat_val, "$batPct%")
            views.setTextViewText(R.id.node_temp_val, "$batTemp°C")

            // ✨ FILL THE NEON RING
            views.setProgressBar(R.id.node_bat_ring, 100, batPct, false)

            // ✨ MANUAL SYNC BUTTON LOGIC
            val syncIntent = Intent(context, PowerNodeProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val pendingSync = PendingIntent.getBroadcast(context, appWidgetId, syncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_sync_power, pendingSync)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ THE MEMORY NODE (2x2)
// ─────────────────────────────────────────────────────────────────────────────
class MemoryNodeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_memory_node)

            // Get RAM
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            am.getMemoryInfo(memInfo)
            val ramPct = (((memInfo.totalMem - memInfo.availMem).toDouble() / memInfo.totalMem) * 100).toInt()

            // Get Storage
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)
            val totalStorage = stat.blockCountLong * stat.blockSizeLong
            val freeStorage = stat.availableBlocksLong * stat.blockSizeLong
            val usedStorage = totalStorage - freeStorage
            val storagePct = if (totalStorage > 0) ((usedStorage.toDouble() / totalStorage) * 100).toInt() else 0

            views.setTextViewText(R.id.node_ram_val, "$ramPct%")
            views.setTextViewText(R.id.node_storage_val, "Storage: $storagePct%")

            // ✨ FILL THE NEON RING
            views.setProgressBar(R.id.node_ram_ring, 100, ramPct, false)

            // ✨ MANUAL SYNC BUTTON LOGIC
            val syncIntent = Intent(context, MemoryNodeProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val pendingSync = PendingIntent.getBroadcast(context, appWidgetId, syncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_sync_memory, pendingSync)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ THE NETWORK UPLINK (2x2)
// ─────────────────────────────────────────────────────────────────────────────
class NetworkUplinkProvider : AppWidgetProvider() {

    // Helper function to get the live IP Address
    private fun getLocalIpAddress(): String {
        try {
            val en = NetworkInterface.getNetworkInterfaces()
            while (en.hasMoreElements()) {
                val intf = en.nextElement()
                val enumIpAddr = intf.inetAddresses
                while (enumIpAddr.hasMoreElements()) {
                    val inetAddress = enumIpAddr.nextElement()
                    if (!inetAddress.isLoopbackAddress && inetAddress is Inet4Address) {
                        return inetAddress.hostAddress?.toString() ?: "--"
                    }
                }
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
        return "Offline"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_network_uplink)

            // 1. Get Live IP
            val ipAddress = getLocalIpAddress()
            views.setTextViewText(R.id.node_ip_val, ipAddress)

            // 2. Get Data Traffic
            val rxBytes = TrafficStats.getTotalRxBytes()
            val txBytes = TrafficStats.getTotalTxBytes()
            val totalBytes = if (rxBytes == TrafficStats.UNSUPPORTED.toLong()) 0L else (rxBytes + txBytes)
            val mb = totalBytes / (1024 * 1024)

            if (mb > 1024) {
                views.setTextViewText(R.id.node_data_val, String.format("Traffic: %.1f GB", mb / 1024.0))
            } else {
                views.setTextViewText(R.id.node_data_val, "Traffic: $mb MB")
            }

            // 3. ✨ MANUAL SYNC BUTTON LOGIC
            val syncIntent = Intent(context, NetworkUplinkProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            val pendingSync = PendingIntent.getBroadcast(context, appWidgetId, syncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.btn_sync_network, pendingSync)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}