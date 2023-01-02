# Pimp My Levoit

![Logo](https://github.com/toaster-code/pip_my_levoit/blob/main/logo.jpg?sanitize=true&raw=true)

A project to pimp up the Levoit LV-H131s with an ESP32 flashed with Tasmota.

## Motivation
I was on the hunt for a fun, small home project. Looking around I remembered how disappointed I was with my Levoit air purifier that only provides a simple color indication to show me the dust particle count in the air! On top of that, I had a bounch of LYWSD03MMC temperature sensors lying around at home that only served to visualize the temperature and humidity, despite providing info using classic Bluetooth and BLE. However, I didn't have a BLE gateway to collect the sensor's messages and using my smartphone bluetooth seemed too slow and inefficient for the task.
At first I tryed to upgrade my setup by flashing an ESP32 with Tasmota and setting up an MQTT gateway with Mosquitto to build a killer IoT network at home for all my sensor data. It worked, but the prototype was just too bulky and clunky for my taste. That's when I had a brilliant idea: why not pimp up my Levoit air purifier and combine both needs into one sleek device? I took apart my Levoit and built a BLE gateway inside it. Now it has two WiFi connections (legacy Levoit and the ESP32), uses MQTT that talks to my Node-RED service to not only receive the LYWSD03MMC measurements, but also to harverst PM2.5 particle measurement from my air purifier. The "Pimp My Levoit" project was born!

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
- Blue :                pm < 70 µg/m3
- Green :   70 µg/m3  \leq pm < 100 µg/m3
- Yellow : 100 µg/m3  \leq  pm < 130 µg/m3
- Red :                 pm  \geq 130 µg/m3

## Errors from message class
    'err_empty_message' = "Message is empty."
    'err_not_bytes' = 'Message must be a bytes object.'
    'err_unknown_header' = 'Unknown message header.'
    'err_checksum' = 'Invalid message checksum.'

##
WIP - (Add the snippets for future development)
[My snippets](snippets.md)
