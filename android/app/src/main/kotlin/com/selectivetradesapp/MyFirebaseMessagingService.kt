package com.selectivetradesapp

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import androidx.annotation.RequiresApi
import android.app.Service
import android.content.BroadcastReceiver
import android.os.IBinder;
import android.util.Log
import androidx.annotation.Nullable

import java.util.Timer
import java.util.TimerTask

@SuppressLint("MissingFirebaseInstanceTokenRefresh")
public class MyFirebaseMessagingService : FirebaseMessagingService() {
    private var ADMIN_CHANNEL_ID = "admin_channel"
    private var db_helper:DbHelper = DbHelper(context = this)

    private var timer: Timer? = null
    private var timerTask: TimerTask? = null
    private var counter = 0
    var oldTime: Long = 0
    fun startTimer() {
        //set a new Timer
        timer = Timer()

        //initialize the TimerTask's job
        initializeTimerTask()

        //schedule the timer, to wake up every 1 second
        timer!!.schedule(timerTask, 1000, 1000) //
    }

    /**
     * it sets the timer to print the counter every x seconds
     */
    fun initializeTimerTask() {
        timerTask = object : TimerTask() {
            override fun run() {
                Log.i("in timer", "in timer ++++  " + counter++)
            }
        }
    }

    /**
     * not needed
     */
    fun stoptimertask() {
        //stop the timer, if it's not already null
        if (timer != null) {
            timer!!.cancel()
            timer = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        val broadcastIntent = Intent(
            this,
            MyBroadcastReceiver::class.java
        )
        sendBroadcast(broadcastIntent)
        stoptimertask()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage){
        var notif_count = 0
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            setupChannels(notificationManager);
        }
        if(remoteMessage != null){
            var channel:String = remoteMessage.data.get("channel").toString()
            notif_count = db_helper.getChannelUnreadMessagesCount(channel)
            notif_count++
            db_helper.saveChannelNotificationCount(channel, notif_count)
            println("MyFirebaseMessagingService.onMessageReceived: message received from $channel")
        }

    }

    override fun onStart(intent: Intent?, startId: Int) {
        super.onStart(intent, startId)
        startTimer()
    }


    @RequiresApi(api = Build.VERSION_CODES.O)
    private fun setupChannels(notificationManager: NotificationManager?) {
        val adminChannelName: CharSequence = "New notification"
        val adminChannelDescription = "Device to device notification"
        val adminChannel: NotificationChannel
        adminChannel = NotificationChannel(
            ADMIN_CHANNEL_ID,
            adminChannelName,
            NotificationManager.IMPORTANCE_HIGH
        )
        adminChannel.setDescription(adminChannelDescription)
        adminChannel.enableLights(true)
        adminChannel.setLightColor(Color.RED)
        adminChannel.enableVibration(true)
        if (notificationManager != null) {
            notificationManager.createNotificationChannel(adminChannel)
        }
    }
}
