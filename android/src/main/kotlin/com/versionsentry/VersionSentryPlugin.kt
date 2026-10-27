package com.versionsentry

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Bridges the Play in-app update API to Dart.
 *
 * A method channel drives the flow (check / start / complete) and an event
 * channel streams [InstallStatus] plus the download byte counters, which Dart
 * turns into a percentage.
 */
class VersionSentryPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler, PluginRegistry.ActivityResultListener {

    private companion object {
        const val METHOD_CHANNEL = "version_sentry/auto_update"
        const val EVENT_CHANNEL = "version_sentry/auto_update_progress"
        const val REQUEST_CODE = 22153
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private var updateManager: AppUpdateManager? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var events: EventChannel.EventSink? = null

    /// Held so startFlexibleUpdate can report whether the user accepted Play's
    /// own confirmation dialog.
    private var flowResult: MethodChannel.Result? = null
    private var listenerRegistered = false

    private val installListener = InstallStateUpdatedListener { state ->
        emit(state.installStatus(), state.bytesDownloaded(), state.totalBytesToDownload())
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        updateManager = AppUpdateManagerFactory.create(binding.applicationContext)

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterInstallListener()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        updateManager = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkForUpdate" -> checkForUpdate(result)
            "startFlexibleUpdate" -> startUpdate(AppUpdateType.FLEXIBLE, result)
            "startImmediateUpdate" -> startUpdate(AppUpdateType.IMMEDIATE, result)
            "completeInstall" -> completeInstall(result)
            else -> result.notImplemented()
        }
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        val manager = updateManager
        if (manager == null) {
            result.error("not_attached", "Plugin is not attached to an engine", null)
            return
        }

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                result.success(
                    mapOf(
                        "available" to (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
                        "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                        "availableVersionCode" to info.availableVersionCode(),
                        "installStatus" to info.installStatus(),
                        "stalenessDays" to info.clientVersionStalenessDays(),
                        "priority" to info.updatePriority()
                    )
                )
            }
            .addOnFailureListener { error ->
                /// Most commonly thrown when the build was not installed from Play.
                result.error("check_failed", error.message, null)
            }
    }

    private fun startUpdate(type: Int, result: MethodChannel.Result) {
        val manager = updateManager
        val host = activity

        if (manager == null || host == null) {
            result.error("no_activity", "No foreground activity to host the update flow", null)
            return
        }
        if (flowResult != null) {
            result.error("in_progress", "An update flow is already running", null)
            return
        }

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE) {
                    result.success(false)
                    return@addOnSuccessListener
                }
                if (!info.isUpdateTypeAllowed(type)) {
                    result.error("type_not_allowed", "Update type $type is not allowed for this app", null)
                    return@addOnSuccessListener
                }

                if (type == AppUpdateType.FLEXIBLE) registerInstallListener()

                try {
                    flowResult = result
                    manager.startUpdateFlowForResult(
                        info,
                        host,
                        AppUpdateOptions.newBuilder(type).build(),
                        REQUEST_CODE
                    )
                } catch (e: Exception) {
                    flowResult = null
                    result.error("start_failed", e.message, null)
                }
            }
            .addOnFailureListener { error ->
                result.error("check_failed", error.message, null)
            }
    }

    private fun completeInstall(result: MethodChannel.Result) {
        val manager = updateManager
        if (manager == null) {
            result.error("not_attached", "Plugin is not attached to an engine", null)
            return
        }

        try {
            manager.completeUpdate()
            result.success(null)
        } catch (e: Exception) {
            result.error("complete_failed", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val pending = flowResult
        flowResult = null

        when (resultCode) {
            Activity.RESULT_OK -> pending?.success(true)
            Activity.RESULT_CANCELED -> {
                emit(InstallStatus.CANCELED, 0, 0)
                pending?.success(false)
            }
            else -> {
                emit(InstallStatus.FAILED, 0, 0)
                pending?.error("update_failed", "Play reported result code $resultCode", null)
            }
        }
        return true
    }

    private fun emit(status: Int, bytesDownloaded: Long, totalBytes: Long) {
        events?.success(
            mapOf(
                "status" to status,
                "bytesDownloaded" to bytesDownloaded,
                "totalBytesToDownload" to totalBytes
            )
        )
    }

    private fun registerInstallListener() {
        if (listenerRegistered) return
        updateManager?.registerListener(installListener)
        listenerRegistered = true
    }

    private fun unregisterInstallListener() {
        if (!listenerRegistered) return
        updateManager?.unregisterListener(installListener)
        listenerRegistered = false
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }
}
