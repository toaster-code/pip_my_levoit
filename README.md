# Pimp My Levoit

<p align="center">
  <img src="https://github.com/toaster-code/pip_my_levoit/blob/main/logo.jpg?sanitize=true&raw=true" alt="image description"> 
    <br>Because we can aways make it better!</br>
</p>

A project to pimp up the Levoit LV-H131s with an ESP32 flashed with Tasmota.

## Motivation
I was on the hunt for a fun, small home project and looking around at home I remembered how disappointed I was with my Levoit air purifier. It provides a simple color indication to show me the dust particle count in the air. On top of that, I had a bounch of LYWSD03MMC temperature / humidity sensors lying around, only used for  visualization of current time measurements despite providing access with classic Bluetooth and BLE but, unfortunatelly, I did not have a BLE gateway to collect the measurements, and using a smartphone seemed too slow and inefficient for this task. Everytime I needed historical data I was limited by the storage capacity of the sensor.

I tryed at first to upgrade my setup by flashing an ESP32 with Tasmota and setting it up with the MQTT protocol using Mosquitto to build a killer IoT network at home for all my sensor data. Well it worked but the prototype was just too bulky and clunky for my taste. That's when I had the brilliant idea: why not use my Levoit air purifier with a ESP32 by combining both needs into one sleek device?

With this in mind, the "Pimp My Levoit" project was born!

I took apart my Levoit and embedded my BLE gateway inside of it to not only harverst power, but to use the ESP32 serial communication to interrogate the Levoit particle sensor (a PM1003). All the coding was done using the Berry language to do the pooling of PM1003 sensor data.
Now, my piped-up Levoit has two WiFi connections (the legacy wifi and the ESP32 one that talks with my IoT network using MQTT. As the other end, a Node-RED service deployed at my server docker container receives the PM2.5 particle measurement from the Levoit particle sensor and the LYWSD03MMC measurements obtained by the ESP that is flashed with Tasmota to operate also as a BLE gateway. 

## Features
- The main feature is to recover PM2.5 data from the Levoit particle sensor.
- The embedded ESP32 can also be used as a Bluetooth gateway to collect Bluetooth/BLE messages from nearby sensors (e.g. LYWSD03MMC sensors with [modified firmware](https://github.com/atc1441/ATC_MiThermometer)) and publish them to an MQTT server.

## Table of contents
- [Bill of Materials](#bill-of-materials)
- [Instructions](#instructions)
- [Information](#information)
- [License](#license)

## Bill of materials
- A Levoit LV-H131s.
- An ESP32 WROOM32 - 30 pins model. May work with a different ESP32 but code adaptation may be necessary if pinout is different.
- A [bidirectional level converter](https://www.sparkfun.com/products/12009) to adapt the ESP 3.3V levels to 5V TTL used by the particle sensor.
- Wires, solder iron, patience. Note that Levoit 131s has a tri-point shaped screw in the upper left corner that may be a little difficult to remove without a proper screwdriver.

## Instructions
- WIP - Add info about the disassembly of the Levoit
- WIP - Add info where to install the ESP32 board
- WIP - Add info about the bypass of the 5V Vin.
- WIP - Add info about when sensor starts/stop and the ESP is aways on in design 2 (Vin from main power supply), or turns off in design 1 (Vin from sensor 5V line)
- WIP - Add info about possible modifications for future upgrades (acess to the reset button, etc)

Add the following commands to autoexec.be

    import PM1003Driver as pm_sensor
    tasmota.add_driver(pm_sensor)

To stop the driver use te following command:

    tasmota.remove_driver(pm_sensor)

## Information
Thresholds used in the levoit color led indicator :
| Color | Range       |
|-------|------------|
| Blue  | PM < 70 µg/m³ |
| Green | 70 µg/m³ <= PM < 100 µg/m³ |
| Yellow| 100 µg/m³ <= PM < 130 µg/m³ |
| Red   | PM >= 130 µg/m³ |


## Errors from message class
    'err_empty_message' = "Message is empty."
    'err_not_bytes' = 'Message must be a bytes object.'
    'err_unknown_header' = 'Unknown message header.'
    'err_checksum' = 'Invalid message checksum.'

##
WIP - (Add the snippets for future development)
[My snippets](snippets.md)
