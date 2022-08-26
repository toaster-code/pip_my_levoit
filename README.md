# pimp_my_levoit
A project to pip up the Levoit LV-H131s using an ESP32.

The idea is to recover PM2.5 data from Levoit air sensor using an ESP32 with Tasmota.

# Table of contents
1. Description

## Bill of materials
- An ESP32 WROOM32 (mine is the 30 pins model).
- A [bidirectional level converter](https://www.sparkfun.com/products/12009) to use the ESP 3.3V with the 5V TTL from the particle sensor.
- Wires, solder iron, patience.
- Screwdrivers (note: Levoit 131s has a tri-point shaped screw in the upper left corner at the back that may be a little difficult to remove without a proper tool).

As bonus, the ESP32 may be used as a smart BLE gateway to publish information from BLE sensors nearby (in my case lots of LYWSD03MMC sensors with [modified firmware 
](https://github.com/atc1441/ATC_MiThermometer))

[My snippets](snippets.md)

## Instructions
Add the following commands to autoexec.be

    import PM1003Driver as pm_sensor
    tasmota.add_driver(pm_sensor)

To stop the driver use te following command:

    tasmota.remove_driver(pm_sensor)
    
## Information
Limits on Levoit:
- Blue : pm < 70 µg/m3
- Green : 100 µg/m3 > pm >= 70 µg/m3
- Yellow : 130 µg/m3 > pm >= 100 µg/m3
- Red : pm > 130 µg/m3

## Errors from message class
    'err_empty_message' = "Message is empty."
    'err_not_bytes' = 'Message must be a bytes object.'
    'err_unknown_header' = 'Unknown message header.'
    'err_checksum' = 'Invalid message checksum.'
