# Pimp My Levoit

![](https://github.com/toaster-code/pip_my_levoit/blob/main/logo.jpg?sanitize=true&raw=true)

A project to pimp up the Levoit LV-H131s with an ESP32 flashed with Tasmota.

Features:
- The main feature is to recover PM2.5 data from Levoit particle sensor.
- In addition, the embedded ESP32 may be used as a bluetooth gateway in order to harvest bluetooth / BLE messages from sensors nearby (useful if you have some LYWSD03MMC sensors with [modified firmware](https://github.com/atc1441/ATC_MiThermometer)) and publish using MQTT to any mosquitto server available.

# Table of contents
WIP - (Add a description)

## Bill of materials
- A Levoit 131.
- An ESP32 ( I am using the WROOM32 - 30 pins model).
- A [bidirectional level converter](https://www.sparkfun.com/products/12009) to adapt the ESP 3.3V levels to 5V TTL used by the PM1003 particle sensor.
- Wires, solder iron, patience.
- Screwdrivers to disassemble the Levoit (note that Levoit 131s has a tri-point shaped screw in the upper left corner that may be a little difficult to remove without a proper tool).

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
- Blue : pm < 70 µg/m3
- Green : 100 µg/m3 > pm >= 70 µg/m3
- Yellow : 130 µg/m3 > pm >= 100 µg/m3
- Red : pm > 130 µg/m3

## Errors from message class
    'err_empty_message' = "Message is empty."
    'err_not_bytes' = 'Message must be a bytes object.'
    'err_unknown_header' = 'Unknown message header.'
    'err_checksum' = 'Invalid message checksum.'

##
WIP - (Add the snippets for future development)
[My snippets](snippets.md)
