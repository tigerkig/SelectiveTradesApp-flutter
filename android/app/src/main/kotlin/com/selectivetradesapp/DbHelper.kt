package com.selectivetradesapp

import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.content.Context
import android.database.Cursor

private var DATABASE_NAME = "selective_app.db"

class DbHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, 1) {

    private lateinit var db:SQLiteDatabase

    private var channel_messages_table = "channel_messages_table"
    private var col_message_id = "id"
    private var col_message = "message"
    private var col_channel = "channel"
    private var col_message_timestamp = "message_timestamp"
    private var col_attachment = "attachment"
    private var col_attachment_type = "attachment_type"
    private var col_unread_messages = "unread_messages"
    private var col_status = "status"

    private var channels_table = "channels_table"
    private var col_channel_id = "id"
    private var col_channel_name = "channel_name"
    private var col_channel_image = "channel_image"
    private var col_number_of_members = "number_of_members"
    private var col_members = "members"

    fun getChannelUnreadMessagesCount(channel_name: String): Int {
        db = this.writableDatabase
        var unread_count:Int = 0
        var query = "select $col_unread_messages from $channels_table where $col_channel_name='$channel_name'"
        var data:Cursor = db.rawQuery(query, null)
        if(data.count != 0){
            while(data.moveToNext())
                unread_count = data.getInt(data.getColumnIndex(col_unread_messages))
        }
        if(unread_count == null)
            return 0
        return unread_count
    }

    fun saveChannelNotificationCount(channel_name: String, count: Int){
        db = this.writableDatabase
        var query = "update $channels_table set $col_unread_messages = $count where $col_channel_name = '$channel_name'"
        db.execSQL(query)
    }

    override fun onCreate(p0: SQLiteDatabase?) {

    }

    override fun onUpgrade(p0: SQLiteDatabase?, p1: Int, p2: Int) {

    }

}