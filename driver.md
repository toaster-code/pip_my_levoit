# Introduction
Tasmota is an open-source firmware for smart home devices that allows for the control and management of connected devices through a web interface. It includes a feature called "Drivers" which allows users to extend its functionalityby adding custom code in the form of a driver.

When the PM1003Message class is added as a driver to Tasmota using the tasmota.add_driver() method, Tasmota will make the methods in the PM1003Message class available to the main Tasmota firmware. This allows the Tasmota firmware to use the methods in the PM1003Message class to communicate with the PM1003 sensor and process the response messages received.
When loaded, a driver shall keep periodically running, which for this driver keeps pooling the sensor for data by sending magic packets and listening to the serial answers.

# How to use
To make it run, add the following commands to the file autoexec.be in the ESP32 flashed with Tasmota:

```Berry
import PM1003Driver as pm_sensor
tasmota.add_driver(pm_sensor)
```

In order to stop the driver you can use the command:

```Berry
tasmota.remove_driver(pm_sensor)
```

# Details

The PM1003Message class is used to parse and validate messages received from a PM1003 sensor over a serial connection. The Tasmota firmware on the device running this code likely uses the PM1003Message class to send request messages to the sensor and process the responses received.

The static variables at the beginning of the class define the patterns for the request and response messages. For example, the request_pm static variable contains the bytes for a message that requests the PM2.5 measurement from the sensor.

The Tasmota firmware can use the parse_pm() method to process a response message from the sensor and extract the PM2.5 measurement. It can also use the get_color() method to determine the color-coded level of the measurement based on the rules specified in the code.

The other methods in the PM1003Message class (e.g. validate(), parse_serial_number(), parse_firmware_version()) can be used to process other types of response messages from the sensor and extract the relevant data.

The Tasmota firmware can use the isvalid() method to verify that a response message from the sensor is valid before attempting to parse it. If the message is invalid, the Tasmota firmware can use the inspect() method to determine the reason for the failure and take appropriate action (e.g. requesting the measurement again, logging an error).

