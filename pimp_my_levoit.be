    # Limits on Levoit:
    # Blue : pm < 70 µg/m3
    # Green : 100 µg/m3 > pm >= 70 µg/m3
    # Yellow : 130 µg/m3 > pm >= 100 µg/m3
    # Red : pm > 130 µg/m3

    import string

    # Errors:
    #     'err_empty_message' = "Message is empty."
    #     'err_not_bytes' = 'Message must be a bytes object.'
    #     'err_unknown_header' = 'Unknown message header.'
    #     'err_checksum' = 'Invalid message checksum.'

    class Message
        # patterns for request message:
        static request_pm = bytes("11020B01E1") # message pattern to request the PM2.5 measurement
        static request_sn = bytes("11011FCF") # message pattern to request the serial number
        static request_ver = bytes("11011ED0") # message pattern to request the firmware version
        # patterns of sensor responses header (first 3 bytes of the message):
        static header_pm = bytes("16110B") # 3 bytes header of a message containing the PM2.5 measurement
        static header_sn = bytes("160B1F") # 3 bytes header of a message containing the serial number
        static header_ver = bytes("160E1E") # 3 bytes header of a message containing the firmware version

        def init(msg_bytes)
            self.msg_bytes = msg_bytes
        end
        ########################################################################
        # return true if the message is valid, false otherwise
        ########################################################################
        def isvalid()
            var ans = Message.check(self.msg_bytes)
            if ans == nil
                return true
            elif ans == 'err_empty_message'
                return false
            elif ans == 'err_not_bytes'
                return false
            elif ans == 'err_unknown_header'
                return false
            elif ans == 'err_checksum'
                return false
            else
                return false # should never happen
            end
        end

        # ##############################################################################
        # Validate a message.
        # ##############################################################################
        static def check(msg)
            var header
            if !isinstance(msg, bytes) # check msg type
                # Exception: Message must be a bytes object.
                return 'err_not_bytes'
            elif msg == bytes('')   # check msg length
                # "Exception: The message is empty."
                return "err_empty_message"
            elif (msg[0..2] != Message.header_pm) &&
                 (msg[0..2] != Message.header_sn) &&
                 (msg[0..2] != Message.header_ver) # check header data
                # "Exception: Invalid message header."
                return "err_unknown_header"
            elif Message.checksum(msg) != 0 # verify checksum
                 # "Exception: Invalid message checksum."
                return "err_checksum"
            else
                return nil # message is valid
            end
        end
        ########################################################################
        # Calculates the checksum of a message. The checksum is the sum of all
        # The message is in bytes format.
        ########################################################################
        static def checksum(msg)
            var cs = 0
            for i: 0..size(msg)-1
                cs += number(msg[i])
            end
            return cs % 256
        end

        ########################################################################
        # Process message for the serial number.
        ########################################################################
        def parse_serial_number(msg_bytes)
            var serial_str = ""
            serial_str += string.format("%04d,", number(msg_bytes[3])*256 + number(msg_bytes[4]))
            serial_str += string.format("%04d,", number(msg_bytes[5])*256 + number(msg_bytes[6]))
            serial_str += string.format("%04d,", number(msg_bytes[7])*256 + number(msg_bytes[8]))
            serial_str += string.format("%04d,", number(msg_bytes[9])*256 + number(msg_bytes[10]))
            serial_str += string.format("%04d.", number(msg_bytes[11])*256 + number(msg_bytes[12]))
            if self.debug
                print("Serial number: " + serial_str)
            end
        end

        ########################################################################
        # Process message for the PM2.5 measurement.
        ########################################################################
        def parse_pm(msg_bytes)
            var pm = number(msg_bytes[3])*256 + number(msg_bytes[4])
            if self.debug
                print("PM2.5: " + pm)
            end
        end

        ########################################################################
        # Process message for firmware version.
        ########################################################################
        def parse_firmware_version(msg_bytes)
            # TODO: parse the firmware version
        end

        ########################################################################
        # Return the type of message.
        ########################################################################
        def type()
            if msg_bytes[0..2] == Message.header_pm
                return "pm"
            elif msg_bytes[0..2] == Message.header_sn
                return "sn"
            elif msg_bytes[0..2] == Message.header_ver
                return "ver"
            else
                return "unknown"
            end
        end

        ########################################################################
        # Return sensor data from message.
        ########################################################################
        def value()
            if self.type() == "pm"
                return self.parse_pm(self.msg_bytes)
            elif self.type() == "sn"
                return self.parse_serial_number(self.msg_bytes)
            elif self.type() == "ver"
                return self.parse_firmware_version(self.msg_bytes)
            else
                return ""
            end
        end
    end

    ##############################################################################
    # autotests for the class Message
    ##############################################################################
    do
        assert(Message.check(bytes('')) == 'err_empty_message') # empty message
        assert(Message.check('abcd') == 'err_not_bytes') # not bytes object
        assert(Message.check(100) == 'err_not_bytes') # not bytes object
        assert(Message.check([10]) == 'err_not_bytes') # not bytes object
        assert(Message.check(bytes('abcdef')) == 'err_unknown_header') # unknown header
        assert(Message.check(bytes('16110B')) == 'err_checksum') # checksum = 0x32
        assert(Message.check(bytes('160E1EBE')) == nil) # 0x16 + 0x0E +0x1E + 0xBE = 0x00
        assert(Message.check(bytes('160B1FC0')) == nil) # 0x16 + 0x0B + 0x1F = 0xC0
        assert(Message.check(bytes('160E1EBE')) == nil) # 0x16 + 0x0E + 0xBE = 0xBD
    end

    ##############################################################################
    # Class that represents a PM2.5 sensor.
    ##############################################################################
    class PM1003Sensor : Driver
        var ser, counter, info, debug
        def init()
            var msg
            self.debug = False # flag to enable/disable debug messages
            self.ser = serial(16, 17, 9600, serial.SERIAL_8N1) # USING UART2 pins: RX_GPIO = 16, TX_GPIO = 17, Baudrate = 9600, 8N1
            self.lock = False # flag to indicate if the sensor communication is locked
            self.retries = 0 # number of retries to send a message
            self.stack = [] # stack of operations to be executed
            self.delay = 100 # delay between stack operations in milliseconds

            if self.ser.available() != -1 :
                print("PM1003 sensor initialized. Requesting Serial Number...")
                self.sn = self.request_sn() # get serial number
                msg = "PM1003 sensor pooling started."
                print(msg)
                # initial pooling:
                self.counter = 0 # counter for the number of times the PM sensor has been polled
                self.send_message(Message.request_pm) # request pm data from sensor
                self.set_info('Powering on', 'Pooling sensor...') # set status info
            else
                var msg = "Error: PM1003 driver not initialized."
                print(msg)
                self.set_info('Offline', msg) # log status
            end
        end

        def set_info(status, msg)
            # log status:
            self.info['status'] = status
            self.info['msg'] = msg
        end

        ########################################################################
        # Request the serial number from the sensor.
        ########################################################################
        def request_sn()
            self.send_message(Message.request_sn) # request serial number from sensor
            tasmota.delay(100) # small delay to allow the serial connection to be established
            if self.ser.available() != -1 :
                self.parse_serial_number() # get serial number
            else
                var msg = "Error: Serial number not received."
                print(msg)
                self.set_info('Offline', msg) # log status
            end
        end
        ########################################################################
        # Request the software version from the sensor.
        ########################################################################
        def request_ver()
            self.send_message(Message.request_ver) # request firmware version from sensor
        end
        ########################################################################
        # Request the PM2.5 measurement from the sensor.
        ########################################################################
        def request_pm()
            self.send_message(Message.request_pm) # request pm data from sensor
        end

        ############################################################################
        # Send message to sensor.
        ############################################################################
        def send_message(msg)
            self.ser.flush() # flush the serial buffer just before sending.
            self.ser.write(msg) # request PM data to sensor
        end

        ############################################################################
        # Read message from buffer.
        ############################################################################
        def read_message()
            ver buffer_size = self.ser.available()
            if  buffer_size == -1
                self.message = Message(bytes('')) # no message available
                self.set_info("Offline", "PM1003 sensor not available.")
            elif buffer_size > 0
                self.message = Message(self.ser.read()) # read the message and store as Message object
                self.set_info("Online", "PM1003 sensor not available.")
            else
                self.message = Message(bytes('')) # no message available
                self.set_info("Pending", "No message available.")
            end
        end

        def pool_sensor()
            var header = "16110B"
            if self.ser.available() >= 20 # get data if received 20 bytes at least
                self.retries = 0 # reset retries

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
                print("No data available. Retrying.")
                self.retries = self.retries + 1
            end
        end
        def every_second()
            self.read() # recover data and then redo a request
            self.request_pmdata() # flush old data and request new information
            self.counter +=1 #increment counter
        end
        def publish()
            # publish the PM2.5 value to the MQTT broker
            # publish the serial number to the MQTT broker
            # publish the counter to the MQTT broker
            self.mqtt.publish("/levoit/pm2.5", self.pm_value)
            self.mqtt.publish("/levoit/serial_number", self.sn)
            self.mqtt.publish("/levoit/counter", self.counter)
        end
          #- display sensor value in the web UI -#
        def web_sensor()
            if true
                # if !self.wire return nil end  #- exit if not initialized -#
                var msg = string.format(
                        "{s}Levoit PM 2.5 {m}%d µg/m³{e}",
                        self.pm_value)
                tasmota.web_send_decimal(msg)
            else
                var msg = string.format(
                        "{s}Levoit PM 2.5 {m}offline{e}")
                tasmota.web_send_decimal(msg)

            end
        end
        #- add sensor value to teleperiod -#
        def json_append()
            if !self.wire return nil end  #- exit if not initialized -#
            import string
            var ax = int(self.accel[0] * 1000)
            var ay = int(self.accel[1] * 1000)
            var az = int(self.accel[2] * 1000)
            var msg = string.format(",\"MPU6886\":{\"AX\":%i,\"AY\":%i,\"AZ\":%i,\"GX\":%i,\"GY\":%i,\"GZ\":%i}",
                    ax, ay, az, self.gyro[0], self.gyro[1], self.gyro[2])
            tasmota.response_append(msg)
        end

        ############################################################################
        # Process stack.
        ############################################################################
        def process_stack()
            if self.stack.size() > 0
                var msg = self.stack.pop() # get the next cmd from stack
                tasmota.
                self.send_message(msg) # send the message to the sensor
            end
        end
    end

    pm_sensor = PM1003Sensor()

    tasmota.add_driver(pm_sensor)

    # copy next line at the berry console to remove the driver:
    # tasmota.remove_driver(pm_sensor)