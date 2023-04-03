package reciever

import android.content.res.Configuration
import android.os.Build
import java.util.Locale

object LocaleSettingsHandler {

    fun setLocale(locale: Locale) {
        // TODO check permission
        var activityManagerNative = Class.forName("android.app.ActivityManagerNative")
        val methodGetDefault = activityManagerNative.getMethod("getDefault")
        methodGetDefault.isAccessible = true

        val activityManager = methodGetDefault.invoke(activityManagerNative)
        // Build.VERSION_CODES.O
        if (Build.VERSION.SDK_INT >= 26) {
            // getConfiguration moved from ActivityManagerNative to ActivityManagerProxy
            activityManagerNative = Class.forName(activityManager::class.java.name)
        }

        val methodGetConfiguration = activityManagerNative.getMethod("getConfiguration")
        methodGetConfiguration.isAccessible = true
        val configuration = methodGetConfiguration.invoke(activityManager) as Configuration

        val configClass = configuration::class.java
        val setLocaleField = configClass.getField("userSetLocale")
        setLocaleField.setBoolean(configuration, true)

        configuration.setLocale(locale)
        configuration.setLayoutDirection(locale)

        val updateConfigMethod = activityManagerNative.getMethod("updateConfiguration", Configuration::class.java)
        updateConfigMethod.isAccessible = true
        updateConfigMethod.invoke(activityManager, configuration)
    }
}