# berry_tasmota_tools
A repository to store tools and snippets to program using berry in tasmota for home automation

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


