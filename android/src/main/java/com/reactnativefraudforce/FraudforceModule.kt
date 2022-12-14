package com.reactnativefraudforce

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import com.iovation.mobile.android.FraudForceConfiguration
import com.iovation.mobile.android.FraudForceManager
import com.perimeterx.mobile_sdk.PerimeterX
import com.perimeterx.mobile_sdk.PerimeterXDelegate
import com.perimeterx.mobile_sdk.main.PXPolicy


const val PX_MAX_START_ATTEMPTS = 10

class FraudforceModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), PerimeterXDelegate {
    val reactContext: ReactApplicationContext = reactContext
    val appContext: Context = reactContext.applicationContext
    val ai = appContext.packageManager.getApplicationInfo(appContext.packageName, PackageManager.GET_META_DATA)
    val iovationKey = ai.metaData.getString("com.betcha.IOVATION_KEY") ?: ""

    private var perimeterXStarted: Boolean = false
    private var perimeterXStartAttempt: Int = 0

    var configuration: FraudForceConfiguration  =  FraudForceConfiguration.Builder()
      .subscriberKey(iovationKey)
      .enableNetworkCalls(true) // Defaults to false if left out of configuration
      .build()



    val fm =  (FraudForceManager.getInstance() as FraudForceManager).initialize(configuration, appContext)


    override fun getName(): String {
        return "Fraudforce"
    }

    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    fun blackbox(promise: Promise) {
      FraudForceManager.getInstance().refresh(appContext)

      var str = FraudForceManager.getInstance().getBlackbox(appContext)

      promise.resolve(str)

    }

    @ReactMethod
    fun startPerimeterX(appId: String, promise: Promise) {
      UiThreadUtil.runOnUiThread {
        Log.d("PerimeterX", "Starting PerimeterX..")
        if (!this.perimeterXStarted && this.perimeterXStartAttempt< PX_MAX_START_ATTEMPTS) {
          PerimeterX.INSTANCE.start(this.appContext as Application,  appId, this, false) { success ->
            this.perimeterXStartAttempt += 1
            if (this.perimeterXStartAttempt >= PX_MAX_START_ATTEMPTS){
              promise.reject("PX Start error", "Unable to start PerimeterX", null)
            }else {
              if (!success) {
                // make sure to start the sdk again when it fails (network issue, etc.)
                Log.d("PerimeterX", "PerimeterX not started...")
                Thread.sleep(1_000)
                this.startPerimeterX(appId, promise)
              } else {
                Log.d("PerimeterX", "PerimeterX started...")
                val policy = PXPolicy()
                policy.requestsInterceptedAutomaticallyEnabled = false
                PerimeterX.INSTANCE.setPolicy(policy, appId)
                this.perimeterXStarted = true
                promise.resolve(null)
              }
            }
          }
        }
      }
    }
  @ReactMethod
  fun getPerimeterXHeaders(promise: Promise) {
    UiThreadUtil.runOnUiThread {
      try {
        var json: WritableMap = Arguments.createMap()
        val headers: HashMap<String, String> = PerimeterX.INSTANCE.headersForURLRequest(null)
        headers.forEach { (key, value) ->
          json.putString(key, value)
        }
        promise.resolve(json);
      } catch (e: Exception) {
        promise.reject("Error getting PX Headers", e.message)
      }
    }

  }


  @ReactMethod
  fun handleResponse(response: String?, code: Int?, url: String?, promise: Promise) {
    UiThreadUtil.runOnUiThread {
      try {
        val isHandledByPX: Boolean = PerimeterX.INSTANCE.handleResponse(null, response!!, code!!)
        promise.resolve(isHandledByPX)
      }catch(e:Exception){
        promise.reject(e)
      }
    }
  }


  override fun perimeterxRequestBlockedHandler(appId: String) {
    val payload = Arguments.createMap()
    // Put data to map
    // Put data to map
    payload.putString("appId", appId)

    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXRequestBlocked", payload)
  }

  override fun perimeterxChallengeSolvedHandler(appId: String) {
    val payload = Arguments.createMap()
    // Put data to map
    // Put data to map
    payload.putString("appId", appId)

    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXChallengeSolved", payload)
  }

  override fun perimeterxChallengeCancelledHandler(appId: String) {
    val payload = Arguments.createMap()
    // Put data to map
    // Put data to map
    payload.putString("appId", appId)

    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXChallengeCancelled", payload)
  }


  @ReactMethod
  fun addListener(eventName: String?) {
  }

  @ReactMethod
  fun removeListeners(count: Int?) {
  }

}



