# Information about UART communication protocol
Information extracted from another Cubic sensor pdf.
Reference:  Laser Particle Sensor Module datasheet
Model: PM2016 Version: V0.2, Date: June 25, 2021

# UART Communication Protocol 1

## 1. General Statement

1) The data in this protocol is all hexadecimal data. For example,“46” for decimal [70].
2) [xx] is for single-byte data (unsigned, 0-255); for double data, high byte is in front of low byte.
3) Baud rate: 9600; Data Bits: 8; Stop Bits: 1; Parity: No
4) After power on the sensor, command shall be sent within 4 seconds.

## 2. Format of Serial Communication Protocol

Sending format to software:

| Start | Symbol | Length | Command | Data 1 | ... | Data n. | Check Sum |
| ----- | ------ | ------ | ------- | ------ | --- | ------- | --------- |
| HEAD  | LEN    | CMD    | DATA1   | ....   | ... | DATAn   | CS        |
| 11H   | XXH    | XXH    | XXH     | ....   | ... | XXH     | XXH       |

Detail description on protocol format:

| Protocol Format | Description                                                             |
| --------------- | ----------------------------------------------------------------------- |
| Start symbol    | Sending by software is fixed as [11H], module respond is fixed as [16H] |
| Length          | Length of frame bytes= data length +1 (including CMD+DATA)              |
| Command         | Command                                                                 |
| Data            | Data of writing or reading, length is not fixed                         |
| Check sum       | Cumulative sum of data = 256- (HEAD+LEN+CMD+DATA)                       |

## 3.  Command Table of Serial Protocol

| Item No. | Function Description                            | Command |
| :------: | ----------------------------------------------- | ------- |
|    1     | Read particle measurement result                | 0x0B    |
|    2     | Open/close particle measurement                 | 0x0C    |
|    3     | Set up and read particle calibrated coefficient | 0x07    |
|    4     | Read software version number                    | 0x1E    |
|    5     | Read serial number                              | 0x1F    |


 ## 4. Detail Description of UART Protocol

This part is my own interpretation of PM1003A sensor data from received messages in berry console at Tasmota.
Note: The checksum last byte is a checksum type sum with 2-complement of all other bytes.

after sent 11 01 1E D0 many times I've got:
~~~
bytes('16110B000003E800000B05000003E80000006286')
bytes('16110B000003E800000B07000003E80000006284')
bytes('16110B000003E800000B09000003E80000006282')
bytes('16110B000003E800000B0B000003E80000006280')
bytes('16110B000003E800000B0D000003E8000000627E')
bytes('16110B000003E800000B0F000003E8000000627C')
bytes('16110B000003E800000B12000003E80000006279')
bytes('16110B000003E800000B15000003E80000006276')
bytes('16110B000003E800000B18000003E80000006273')
bytes('16110B000003E800000B1B000003E80000006270')
bytes('16110B000003E800000B1E000003E8000000626D')
~~~
from last message as example, we get:

|                          16 11 0B                          |   00 00 03 E8   |   00 00 0B 1E   |    00 00 03 E8     |     00 00 00 62     |    6D    |
| :--------------------------------------------------------: | :-------------: | :-------------: | :----------------: | :-----------------: | :------: |
| HEADER <br /> (Start symbol, <br /> num bytes <br />  cmd) | DF1 DF2 DF3 DF4 | DF5 DF6 DF7 DF8 | DF9 DF10 DF11 DF12 | DF13 DF14 DF15 DF16 | Checksum |

The information is the hexadecimal values 0x03 0xE8 which appears in other parts of the message for some unknown reason.
The datasheet informs that bytes DF3 and DF4 are the PM 2.5 measurement, depicted as 256*DF3 + DF4
