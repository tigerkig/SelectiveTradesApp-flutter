package com.selectivetradesapp

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager.LayoutParams
import com.google.firebase.analytics.FirebaseAnalytics
import io.flutter.embedding.engine.FlutterEngine
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.ktx.Firebase

class MainActivity: FlutterActivity() {

    private lateinit var firebaseAnalytics: FirebaseAnalytics

    private var mServiceIntent: Intent? = null
    private var service: MyFirebaseMessagingService? = null
    private var ctx: Context? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        window.addFlags(LayoutParams.FLAG_SECURE)
    }

    fun getCtx(): Context? {
        return ctx
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        firebaseAnalytics = Firebase.analytics
        ctx = this
        service = MyFirebaseMessagingService()
        mServiceIntent = Intent(getCtx(), service!!.javaClass)
        if (!isMyServiceRunning(service!!.javaClass)) {
            startService(mServiceIntent)
        }
    }

    private fun isMyServiceRunning(serviceClass: Class<*>): Boolean {
        val manager: ActivityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.getClassName()) {
                Log.i("isMyServiceRunning?", true.toString() + "")
                return true
            }
        }
        Log.i("isMyServiceRunning?", false.toString() + "")
        return false
    }


    override fun onDestroy() {
        super.onDestroy()
        if(mServiceIntent != null)
            stopService(mServiceIntent)
        Log.i("MAINACT", "onDestroy!")
    }
}
