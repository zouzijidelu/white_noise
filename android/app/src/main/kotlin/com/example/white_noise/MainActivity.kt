package com.example.white_noise

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun onBackPressed() {
        // 按返回键时，将应用退到后台而不是关闭 Activity
        moveTaskToBack(false)
    }
}
