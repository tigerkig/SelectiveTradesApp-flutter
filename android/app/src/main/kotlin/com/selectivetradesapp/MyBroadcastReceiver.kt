package com.selectivetradesapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class MyBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        context.startService(Intent(context, MyFirebaseMessagingService::class.java))
    }
}