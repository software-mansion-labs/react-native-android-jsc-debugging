# ReactNative Android JSC debugging

Allows to use Chrome Debugger against ReactNative applications, while still running on Android device.

## How to use with scripts

1. `npm run build`
2. Connect react native application (description bellow)
3. Start app
4. `npm run start`

## How to use it manually

1. Compile android-jsc
```
cd ./jsc-android-buildscripts && npm run download &&  npm run start
```

2. Connect react native application
 
```git diff 7742968 example```
```patch
diff --git a/example/android/app/build.gradle b/example/android/app/build.gradle
index 64b7095..4004e6c 100644
--- a/example/android/app/build.gradle
+++ b/example/android/app/build.gradle
@@ -136,10 +136,30 @@ android {
     }
 }
 
+
+// no intl build
+//configurations.all {
+//    resolutionStrategy {
+//        force 'org.webkit:android-jsc:r236355'
+//    }
+//}
+
+
+// intl build
+configurations.all {
+    resolutionStrategy {
+        eachDependency { DependencyResolveDetails details ->
+            if (details.requested.name == 'android-jsc') {
+                details.useTarget group: details.requested.group, name: 'android-jsc-intl', version: 'r236355'
+            }
+        }
+    }
+}
 dependencies {
     implementation fileTree(dir: "libs", include: ["*.jar"])
     implementation "com.android.support:appcompat-v7:${rootProject.ext.supportLibVersion}"
-    implementation "com.facebook.react:react-native:+"  // From node_modules
+    api project(":ReactAndroid")
+    api 'org.webkit:android-jsc:r236355'
 }
 
 // Run this once to be able to run the application with BUCK
diff --git a/example/android/build.gradle b/example/android/build.gradle
index a1e8085..8ee4e83 100644
--- a/example/android/build.gradle
+++ b/example/android/build.gradle
@@ -14,6 +14,7 @@ buildscript {
     }
     dependencies {
         classpath 'com.android.tools.build:gradle:3.1.4'
+        classpath 'de.undercouch:gradle-download-task:3.4.3'
 
         // NOTE: Do not place your application dependencies here; they belong
         // in the individual module build.gradle files
@@ -26,8 +27,8 @@ allprojects {
         google()
         jcenter()
         maven {
-            // All of React Native (JS, Obj-C sources, Android binaries) is installed from npm
-            url "$rootDir/../node_modules/react-native/android"
+            // Local Maven repo containing AARs with JSC library built for Android
+            url "$rootDir/../../jsc-android-buildscripts/dist"
         }
     }
 }
diff --git a/example/android/settings.gradle b/example/android/settings.gradle
index 13df8b5..8f98edd 100644
--- a/example/android/settings.gradle
+++ b/example/android/settings.gradle
@@ -1,3 +1,7 @@
 rootProject.name = 'example'
 
 include ':app'
+
+include ':ReactAndroid'
+project(':ReactAndroid').projectDir = new File(rootProject.projectDir, '../../react-native/ReactAndroid')
+// project(':ReactAndroid').projectDir = new File(PATH_TO_RN_DIRECTORY, 'react-native/ReactAndroid')
diff --git a/example/package.json b/example/package.json
index 74209e2..e14c52e 100644
--- a/example/package.json
+++ b/example/package.json
@@ -8,7 +8,7 @@
   },
   "dependencies": {
     "react": "16.6.1",
-    "react-native": "0.57.7"
+    "react-native": "0.58.0-rc.0"
   },
   "devDependencies": {
     "babel-jest": "23.6.0",
@@ -19,4 +19,4 @@
   "jest": {
     "preset": "react-native"
   }
-}
\ No newline at end of file
+}
```

3. Build
```
cd remotedebug-ios-webkit-adapter && git reset --hard && cd .. && patch -d ./remotedebug-ios-webkit-adapter -p1 < remotedebug-ios-webkit-adapter.patch
```
4. Run ReactNative application on Android device
5. Keep Android device connected to the computer
6. Execute `adb forward tcp:9123 tcp:9123`
7. Run `plist-websocket-proxy.rb`
8. Run remotedebug-ios-webkit-adapter
9. Navigate to `chrome://inspect` in a Chrome browser
10. Click on `Configure` and add `localhost:9000`

You can replace steps 4,5 with editing `plist-websocket-proxy.rb` with phone's IP.

# PList - websocket proxy

Translates PropertyList serialized messages to websocket

## Dependencies

To install dependencies run `bundle`. If you don't have this command run `gem install bundler`. If you don't have `gem` command install ruby.

## Running

`./plist-websocket-proxy.rb`
