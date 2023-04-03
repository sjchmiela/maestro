package reciever

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.apache.commons.lang3.LocaleUtils
import java.util.Locale

class LocaleReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("Maestro", "In locale receiver")
        val language = intent.getStringExtra("lang")
        val country = intent.getStringExtra("country")

        if (language == null || country == null) {
            return
        }

        //val locale = Locale(language, country)

//        val resolvedLocale = if (!LocaleUtils.isAvailableLocale(locale)) {
//            val approximateMatchesLocales = matchLocale(language, country)
//            approximateMatchesLocales.first()
//        } else {
//            null
//        }

//        if (resolvedLocale == null) {
//            Log.e("Maestro", "Not able to resolve approximate locale")
//        }

        val locale = Locale.Builder().setLocale(Locale("zh", "CN")).setScript("Hans").build()
        LocaleHandler().setLocale(locale)
    }

    private fun matchLocale(language: String, country: String): List<Locale> {
        val matches = mutableListOf<Locale>()
        LocaleUtils.availableLocaleList().forEach {
            if (it.language.equals(language, ignoreCase = true) && it.country.equals(country, ignoreCase = true)) {
                matches.add(it)
            }
        }
        return matches.toList()
    }
}