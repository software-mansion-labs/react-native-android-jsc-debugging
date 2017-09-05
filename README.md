# ReactNative Android JSC debugging

Allows to use Chrome Debugger against ReactNative applications, while still running on Android device.

## How to use it all?

1. Compile android-jsc using https://github.com/SoftwareMansion/jsc-android-buildscripts/tree/reactNativeDebugger (use https://github.com/ukasiu/webkit/tree/reactNativeDebugger for webkit sources)
2. Build ReactNative application using android-jsc from step 1
3. Run ReactNative application on Android device
4. Keep Android device connected to the computer
5. Execute `adb forward tcp:9123 tcp:9123`
6. Run `plist-websocket-proxy.rb`
7. Run https://gl.swmansion.com/lukasz-gurdek/remotedebug-ios-webkit-adapter/tree/reactNativeDebugger
8. Navigate to `chrome://inspect` in a Chrome browser
9. Click on `Configure` and add `localhost:9000`

You can replace steps 4,5 with editing `plist-websocket-proxy.rb` with phone's IP.

# PList - websocket proxy

Translates PropertyList serialized messages to websocket

## Dependencies

To install dependencies run `bundle`. If you don't have this command run `gem install bundler`. If you don't have `gem` command install ruby.

## Running

`./plist-websocket-proxy.rb`