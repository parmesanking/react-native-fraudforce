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
import com.perimeterx.mobile_sdk.main.PXPolicyUrlRequestInterceptionType


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
    fun startPerimeterX(appId: String, forDomains: ArrayList<String>, promise: Promise) {
      UiThreadUtil.runOnUiThread {
        Log.d("PerimeterX", "Starting PerimeterX..")
        val policy = PXPolicy()
        policy.doctorCheckEnabled = false
        policy.setDomains(forDomains, appId)
        policy.urlRequestInterceptionType = PXPolicyUrlRequestInterceptionType.NONE


        if (!this.perimeterXStarted && this.perimeterXStartAttempt< PX_MAX_START_ATTEMPTS) {
          try {
            PerimeterX.start(this.appContext as Application,  appId, this, policy)
            Log.d("PerimeterX", "PerimeterX started...")

            this.perimeterXStarted = true
            promise.resolve(null)

          } catch (error:Exception) {
            Log.d("PerimeterX", error.message!!)

            this.perimeterXStartAttempt += 1
            if (this.perimeterXStartAttempt >= PX_MAX_START_ATTEMPTS) {
              promise.reject("PX Start error", "Unable to start PerimeterX", error)
            } else {
              // make sure to start the sdk again when it fails (network issue, etc.)
              Log.d("PerimeterX", "PerimeterX not started...")
              Thread.sleep(1_000)
              this.startPerimeterX(appId, forDomains, promise)

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
        val headers: HashMap<String, String> = PerimeterX.headersForURLRequest(null)
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
        val isHandledByPX: Boolean = PerimeterX.handleResponse(response!!, null, null)
        promise.resolve(isHandledByPX)
      }catch(e:Exception){
        promise.reject(e)
      }
    }
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

  override fun perimeterxChallengeSolvedHandler(appId: String) {
    val payload = Arguments.createMap()
    // Put data to map
    // Put data to map
    payload.putString("appId", appId)

    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXChallengeSolved", payload)
  }

  override fun perimeterxHeadersWereUpdated(headers: HashMap<String, String>, appId: String) {
    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXHeadersUpdated", headers)

  }

  override fun perimeterxRequestBlockedHandler(url: String?, appId: String) {
    val payload = Arguments.createMap()
    // Put data to map
    // Put data to map
    payload.putString("appId", appId)
    payload.putString("url", url)

    this.reactContext
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("onPerimeterXRequestBlocked", payload)
  }

  @ReactMethod
  fun addListener(eventName: String?) {
  }

  @ReactMethod
  fun removeListeners(count: Int?) {
  }

}



