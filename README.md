# pimp_my_levoit
A project to pip up the Levoit LV-H131s using an ESP32.

The idea is to recover PM2.5 data from Levoit air sensor using an ESP32 with Tasmota.

## Bill of materials
- An ESP32 WROOM32 (mine is the 30 pins model).
- A [bidirectional level converter](https://www.sparkfun.com/products/12009) to use the ESP 3.3V with the 5V TTL from the particle sensor.
- Wires, solder iron, patience.
- Screwdrivers (note: Levoit 131s has a tri-point shaped screw in the upper left corner at the back that may be a little difficult to remove without a proper tool).

As bonus, the ESP32 may be used as a smart BLE gateway to publish information from BLE sensors nearby (in my case lots of LYWSD03MMC sensors with [modified firmware 
](https://github.com/atc1441/ATC_MiThermometer))

[My snippets](snippets.md)
