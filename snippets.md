
# Snippets
A file to store my snippets used for testing my PM1003 sensor using berry language in tasmota for home automation.

References:
https://github.com/Skiars/berry_doc/releases/download/latest/berry_short_manual.pdf
https://tasmota.github.io/docs/Berry/#tasmota-object


## Code for serial communications using ESP32 (WROOM 32)
### 1 - Using GPIO 3 to receive, GPIO 4 to transmit data using ESP32

    ser = serial(3, 4, 9600, serial.SERIAL_8N1)
    msg = ser.read()   # read bytes from serial as bytes
    print(msg)   # print the message as string
    ser.available() #check read buffer (max 256 bytes)


### 2 - Instruction to set a timer to run a function
"*fun*" is  a enclosure containing a function.
Note: Does not seems to work properly when fun is a method from a class.

    tasmota.set_timer(200, fun)


### 3 - Sample class that works as a driver

    class MyDriver    
        def init(n)
            self.c=0        
            if n == nil
                self.n = 5
            else        
                self.n = n
            end
            self.cf = self.c + n
        end
        def increment()
            if self.c >= self.cf
                print("finished")            
            else
                self.c +=1
            end
        end
        def every_second()
            print("Booh! number " + str(self.c))
            self.increment()
        end
        def print()
            print("counter = " + str(self.c))
        end
        def loop()        
            for i : 1..5
                tasmota.set_timer(1000, self.every_second)
            end
        end
    end
    
    d1 = MyDriver()

### 4 - Helper that repeats a function at a given time using *tasmota.set_timer*
ref: https://tasmota.github.io/docs/Berry/#call-function-at-intervals
Note: for faster pooling, please use other method.
Id is a key used to recover the timer to remove it later on.


    def set_timer_modulo(delay,f,id)
      var now=tasmota.millis()
      tasmota.set_timer((now+delay/4+delay)/delay*delay-now, def() set_timer_modulo(delay,f) f() end, id)
    end
    
    def remove_timer(id)
        tasmota.remove_timer(id)
    end
    
    var c = 0
    def loop()    
        c += 1
        print(c)        
    end
    
    # uncomment the following line to set a timer with the key "my_id_timer" in a loop:
    # set_timer_modulo(1000,loop,"my_id_timer")
    
    # run the following command to remove the timer for "my_id_timer":
    # remove_timer("my_id_timer")
    

### 5 - Driver generic from docs
    class my_driver
      def every_100ms()
        # called every 100ms via normal way
      end

      def fast_loop()
        # called at each iteration, and needs to be registered separately and explicitly
      end

      def init()
        # register fast_loop method
        tasmota.add_fast_loop(/-> self.fast_loop())
        # variant:
        # tasmota.add_fast_loop(def () self.fast_loop() end)
      end
    end

    tasmota.add_driver(my_driver())                     # register driver
    tasmota.add_fast_loop(/-> my_driver.fast_loop())    # register a closure to capture the instance of the class as well as the method

### 6 - Loop hexadecimal values in an array:
    import string
    for i:0..255
        print(bytes(string.hex(i)))
    end
### 7 - Set a loop to try connection to a PM1003 sensor to recover the command that works in serial:
    import string
    ser = serial(3, 4, 9600, serial.SERIAL_8N1)
    for i:0..255
        var y = bytes(string.hex(i)) + bytes("01") + bytes("01")
        ser.write(y)
        print(y)
    end

    tasmota.set_timer(3000, def() print(ser.available()) end)
    
### 8 - TEMTOP 900M
    #code still under work
    ser = serial(3, -1, 9600, serial.SERIAL_8N1)

    for i:1..200
    msg = ser.read()   # read bytes from serial as bytes
    print(msg)   # print the message as string
    end

    # BIT DECODING:

    424D - Frame Header (start bit)
    001C - Frame length
    xxxx - PM1.0 Concentration microgram/m3
    xxxx - PM2.5 Concentration microgram/m3
    xxxx - PM10 Concentration microgram/m3
    xxxx - PM1.0 Concentration microgram/m3 (atmospheric environment)
    xxxx - PM2.5 Concentration microgram/m3 (atmospheric environment)
    xxxx - PM10 Concentration microgram/m3 (atmospheric environment)
    xxxx - Particle (diameter >0.3) count/0.1L
    xxxx - Particle (diameter >0.5) count/0.1L
    xxxx - Particle (diameter >1.0) count/0.1L
    xxxx - Particle (diameter >2.5) count/0.1L
    xxxx - Particle (diameter >5) count/0.1L
    xxxx - Particle (diameter >10) count/0.1L
    8000 - Reserve
    xxxx - CRC check from data from start bit to reserve


### *8 - Request info using serial to the particle sensor PM1003A from CUBIC*
Template:
Read Measures Result of Particles:
Send: 11 02 0B 01 E1
Response: 16 11 0B DF1-DF4 DF5-DF8 DF9-DF12 DF13 DF14 DF15 DF16 [CS]
Note: PM2.5 (μg/m³)= DF3*256+DF4 (You should change the HEX to Decimal)
DF1-DF2 reserved, DF5-DF16 reserved

#### Example of message got from sensor:
bytes('16110B000003E800000C8F000003E80000005FFE')
16 11 0B 00 00 03 E8 00 00 0C 8F 00 00 03 E8 00 00 00 5F FE
HEADER = 16110B 
DF1 = 00; DF2 = 00; DF3 = 03; DF4 = E8
DF5 = 00; DF6 = 00; DF7 = 0C; DF8 = 8F
DF9 = 00 DF10 = 00; DF11 = 03; DF12 = E8
DF13 = 00; DF14 = 00; DF15 = 00; DF16 = 5F
CS = FE

    # GPIO16 - RX UART2; GPIO17 - TX UART2
    # PM1003A
    import string    
    ser = serial(16, 17, 9600, serial.SERIAL_8N1)
    
    ser.write(bytes("11020B01E1"))
    msg = ser.read()   # read bytes from serial as bytes
    print(msg)   # print the message as string       
    header = "16110B" # header of data to search in the receive buffer
    # ser.available() #check read buffer (max 256 bytes):
    if ser.available() >= 20 #get data if received 20 bytes at least
        msg = ser.read() #read buffer into msg        
        var idx_start = string.find(msg.tohex(), header) #get the index of the header (string index, not byte index)
        if idx_start == -1
            print('Header not found. Skipping iteration.')
        else        
            idx_start = idx_start/2 #byte index is string index divided by 2:
            var idx_DF3 = 5 + idx_start
            # get integer values from bytes:
            var DF3 = msg[idx_DF3] # DF3 as decimal 
            var DF4 = msg[idx_DF3+1] # DF4 as decimal
            
            #convert to number and calculate PM2.5:
            var pm = number(DF3*256+DF4)
            print("PM2.5 = " + pm + "(μg/m³)")
        end
    end
    
This code runs line by line. Next example shall provide a class to initialize and use cron to repeat the pooling of data.


### 9 - Full 1 second refresh of PM sensor. Creating a Driver for Tasmota for PM1003 Sensor:
As the title says, this consolidates all the knowledge obtained with Tasmota and Berry tests for serial comunications.
    
~~~
# Limits on Levoit:
# Blue : pm < 65 ug/m3
# Green : 100 ug/m3 > pm >= 65 ug/m3
# Yellow : 130 ug/m3 > pm >= 100 ug/m3
# Red : pm > 130 ug/m3
import string
class PM1003Sensor : Driver
    var ser, header, msg, pm_value, counter, sn, pm_bytes 
    def init()                   
        # USING UART2 pins: RX_GPIO = 16, TX_GPIO = 17
        self.ser = serial(16, 17, 9600, serial.SERIAL_8N1)
        # get serial number:
        self.sn = self.request_and_parse_serial_number()
        # an initial pooling:
        self.request_pmdata()
        self.pm_bytes = bytes(20) # pre-allocate 20 bytes to the PM message            
        self.pm_value = ""
        self.counter = 0
    end
    def request_pmdata()
        self.ser.flush()
        self.ser.write(bytes("11020B01E1"))
    end

    def request_and_parse_serial_number()
        # Method that requests the serial number of the sensor
        # not suitable to use in a loop (due to the use of tasmota.delay)
        # Example of ANSWER:
        # 16 0B 1F 00 00 00 7A 02 5C 00 6C 03 46 33
        self.ser.flush() # flush the buffer
        tasmota.delay(50) #small delay to allow the serial number to be read
        self.ser.write(bytes("11011FCF")) # request the serial number            
        tasmota.delay(50) #small delay to allow the serial number to be read          
        print(self.ser.available())
        tasmota.delay(50) #small delay to allow the serial number to be read
        var serial_bytes = self.ser.read() # read the serial number
        #verify checksum:
        # print(serial_bytes)
        if self.checksum(serial_bytes)
            # get info from bytes:
            var serial_str = string.format("%04d,", number(serial_bytes[3])*256 + number(serial_bytes[4]))
            serial_str += string.format("%04d,", number(serial_bytes[5])*256 + number(serial_bytes[6]))
            serial_str += string.format("%04d,", number(serial_bytes[7])*256 + number(serial_bytes[8]))
            serial_str += string.format("%04d,", number(serial_bytes[9])*256 + number(serial_bytes[10]))
            serial_str += string.format("%04d.", number(serial_bytes[11])*256 + number(serial_bytes[12]))
            print("Serial number: " + serial_str)
            return serial_str   
        else
            print("Error: checksum failed, skipping")
            self.ser.flush() # flush the buffer
            return "Checksum failed"
        end
    end
    def checksum(msg_bytes)
        # Method that calculates the checksum of the message
        var cs = 0
        for i: 0..size(msg_bytes)-1
            cs += number(msg_bytes[i])
        end
        cs = cs % 256
        if cs % 256 == 0
            return true # Checksum OK
        else
            return false # Checksum error
        end
    end
    def read()            
        var header = "16110B"
        if self.ser.available() >= 20 # get data if received 20 bytes at least
            self.pm_bytes = self.ser.read() #read buffer into msg        
            var idx_start = string.find(self.pm_bytes.tohex(), header) #get the index of the header (string index, not byte index)
            if idx_start == -1
                print('Header not found. Skip.')
            else
                var idx = idx_start/2 #byte index is string index divided by 2                    
                if self.checksum(self.pm_bytes[idx..idx+20]) # test checksum:        
                    var idx_DF3 = idx + 5 # index of DF3
                    var idx_DF4 = idx_DF3 + 1 # index of DF4
                    # get integer values from bytes:
                    var DF3 = self.pm_bytes[idx_DF3] # DF3 as decimal 
                    var DF4 = self.pm_bytes[idx_DF4] # DF4 as decimal
                    #convert to a number and calculate PM2.5:
                    self.pm_value = number(DF3*256+DF4)
                    print("(" + str(self.counter) + ") " + "PM2.5 = " + str(self.pm_value) + "(μg/m³)")
                    print(self.pm_bytes)                        
                else # checksum error
                    print("Checksum error. Skip and flush.")
                end                    
            end
        else
            print("No data available. Skip.")
        end            
    end
    def every_second()                
        self.read() # recover data and then redo a request
        self.request_pmdata() # flush old data and request new information
        self.counter +=1 #increment counter
    end
end

pm_sensor = PM1003Sensor()

tasmota.add_driver(pm_sensor)

# copy next line at the berry console to remove the driver:
# tasmota.remove_driver(pm_sensor)
~~~    
    
    
