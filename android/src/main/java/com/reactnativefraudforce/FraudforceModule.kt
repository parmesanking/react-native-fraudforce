package com.reactnativefraudforce

import android.content.Context
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.iovation.mobile.android.FraudForceConfiguration
import com.iovation.mobile.android.FraudForceManager

class FraudforceModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    val appContext: Context = reactContext.applicationContext
    val ai = appContext.packageManager.getApplicationInfo(appContext.packageName, PackageManager.GET_META_DATA)
    val iovationKey = ai.metaData.getString("com.betcha.IOVATION_KEY") ?: ""


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


}



