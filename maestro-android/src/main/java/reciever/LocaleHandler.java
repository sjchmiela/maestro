package reciever;

import android.app.ActivityManager;
import android.content.res.Configuration;
import android.os.Build;
import android.util.Log;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Locale;

public class LocaleHandler {
    private static final String TAG = "APPIUM SETTINGS(LOCALE)";
    private static final String CHANGE_CONFIGURATION = "android.permission.CHANGE_CONFIGURATION";

    public void setLocale(Locale locale) {
        try {
            setLocaleWith(locale);
        } catch (Exception e) {
            Log.e(TAG, "Failed to set locale", e);
        }
    }

    private void setLocaleWith(Locale locale) throws
                                              ClassNotFoundException, NoSuchMethodException, InvocationTargetException, IllegalAccessException, NoSuchFieldException {
        Class<?> activityManagerNativeClass = Class.forName("android.app.ActivityManagerNative");

        Method methodGetDefault = activityManagerNativeClass.getMethod("getDefault");
        methodGetDefault.setAccessible(true);
        Object amn = methodGetDefault.invoke(activityManagerNativeClass);

        // Build.VERSION_CODES.O
        if (Build.VERSION.SDK_INT >= 26) {
            // getConfiguration moved from ActivityManagerNative to ActivityManagerProxy
            activityManagerNativeClass = Class.forName(amn.getClass().getName());
        }

        Method methodGetConfiguration = activityManagerNativeClass.getMethod("getConfiguration");
        methodGetConfiguration.setAccessible(true);
        Configuration config = (Configuration) methodGetConfiguration.invoke(amn);

        Class<?> configClass = config.getClass();
        Field f = configClass.getField("userSetLocale");
        f.setBoolean(config, true);

        config.locale = locale;
        config.setLayoutDirection(locale);

        Method methodUpdateConfiguration = activityManagerNativeClass.getMethod("updateConfiguration", Configuration.class);
        methodUpdateConfiguration.setAccessible(true);
        methodUpdateConfiguration.invoke(amn, config);
    }
}