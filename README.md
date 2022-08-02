# berry_tasmota_tools
A repository to store tools and snippets to program using berry in tasmota for home automation

# Code for serial communications using ESP32 (WROOM 32)
## 1 - Using GPIO 3 to receive, GPIO 4 to transmit data using ESP32

    ser = serial(3, 4, 9600, serial.SERIAL_8N1)
    msg = ser.read()   # read bytes from serial as bytes
    print(msg)   # print the message as string
    ser.available() #check read buffer (max 256 bytes)


## 2 - Instruction to set a timer to run a function
"*fun*" is  a enclosure containing a function.
Note: Does not seems to work properly when fun is a method from a class.

    tasmota.set_timer(200, fun)


## 3 - Sample class that works as a driver

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

## 4 - Helper that repeats a function at a given time using *tasmota.set_timer*
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
