package dev.mobile.maestro.sdk.playground

import android.app.Application
import dev.mobile.maestro.sdk.MaestroSdk

class App : Application() {

    override fun onCreate() {
        super.onCreate()

        MaestroSdk.init("d2b3a603-9212-46eb-a23a-be13a997ed3c")
    }
}