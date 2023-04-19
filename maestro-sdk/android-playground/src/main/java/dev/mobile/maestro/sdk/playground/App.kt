package dev.mobile.maestro.sdk.playground

import android.app.Application
import dev.mobile.maestro.sdk.MaestroSdk

class App : Application() {

    override fun onCreate() {
        super.onCreate()

        MaestroSdk.init("1c1291f2-578f-46bc-8ecc-f61477b1fefa")
    }
}