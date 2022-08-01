# SULPOM-Logger

An iOS application used to connect to 1 or more of PNI Sensor's LPOM or SULPOM sensor modules. Connected sensors
can then be logged simultaneously. The resulting JSON log can then be exported.

This application has Nstrumenta `WebSocket Streaming` and `File Upload` functionality built in.

This application is designed to run on iOS 12.1 or later.

To build this application, you will need a machine running macOS with the program Xcode installed.

This application has been tested with:

- macOS 12.3.1

- Xcode 13.4.1

This project has several external dependencies. They are managed with Swift Package Manager which
is build into Xcode. The dependencies are:

- [AlamoFire](https://github.com/Alamofire/Alamofire)

- [StarScream](https://github.com/daltoniam/Starscream)

- [SDCAlertView](https://github.com/scottcwilliams511/SDCAlertView) Fork


## Nstrumenta WebSocket Streaming

Usage:

1. Connect to 1 or more sensors and switch to the `Logging` tab.

2. Tap `Settings` and then tap `Nstrumenta Streaming`.

3. Toggle the switch to the on state.

4. Enter a Nstrumenta WebSocket URL and an API Key.

5. Tap connect. After wating a few seconds, the "Connect" button will change to "Disconnect" which
indicates it successfully connected.

6. You can enable the Auto Connect switch if desired. When enabled, the application will attempt to automatically
connect you to the Nstrumenta WebSocket server when you visit the `Logging` tab.

7. Now when logging, the logs will be sent to the Nstrumenta WebSocket Server.

To consume these logs, you will have to implmenent a Nstrumenta WebSocket client that subscribes to the appropriate
channels. A `Browser` and `Node.js` client can be found here: https://github.com/nstrumenta/nstrumenta

These are the channels that are used:

- `loggingStarted`: Indicates that the user has started a logging session. The message body contains various headers
including sensor information and information about the user's devices.

- `loggingStopped`: Indicates that the user has stopped a logging session. The message body is an empty object.

- `MAG_RAW`: Raw 3-axis magnetometer reading.

- `MAG_AUTOCAL`: Fully calibrated 3-axis magnetometer reading.

- `ACCEL_RAW`: Raw 3-axis accelerometer reading.

- `ACCEL_AUTOCAL`: Fully calibrated 3-axis accelerometer reading.

- `GYRO_RAW`: Raw 3-axis gyroscope reading.

- `GYRO_AUTOCAL`: Fully calibrated 3-axis gyroscope reading.

- `Q_MAG_ACCEL`: A 6-axis quaternion comprised of magnetometer and accelerometer.

- `Q_9AXIS`: A 9-axis quaternion comprised of magnetometer, accelerometer, and gyroscope.

- `LINEAR_ACCEL`: 3-axis linear acceleration reading. This is calculated from `ACCEL_AUTOCAL` with the down vector removed.

- `GYRO_BIAS`: 3-axis gyroscope bias readings.

- `TEMPERATURE`: Current temperature reading in degrees celsius. This will arrive once per second.

- `PRESSURE`: Current pressure reading in hPa.

- `TIMESTAMP_FULL`: The full 64 bit timestamp. This will arrive once every 5 seconds.


## Nstrumenta File Upload

Usage:

1. Connect to 1 or more sensors and switch to the `Logging` tab.

2. Tap `Settings` and then tap `Nstrumenta File Upload`.

3. Toggle the switch to the on state.

4. Enter an API Key.

5. Now, an alert will be shown when logging is finished asking if you wish to upload the JSON. log. If you tap yes, then the file will be upload to Nstrumenta.
