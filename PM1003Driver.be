# ######################################
# PM1003 driver written in Berry
# Author: Fabio Manzoni
########################################
# Limits on Levoit:
# Blue : pm < 70 µg/m3
# Green : 100 µg/m3 > pm >= 70 µg/m3
# Yellow : 130 µg/m3 > pm >= 100 µg/m3
# Red : pm > 130 µg/m3

# Tip: adding "persist.pm1003_debugmode = true" to _persist.json activates debug in the script.

import string
class PM1003Message
    var raw_message, debug
    # patterns for request message:
    static request_pm = bytes("11020B01E1") # message pattern to request the PM2.5 measurement
    static request_sn = bytes("11011FCF") # message pattern to request the serial number
    static request_ver = bytes("11011ED0") # message pattern to request the firmware version
    # patterns of sensor responses header (first 3 bytes of the message):
    static header_pm = bytes("16110B") # 3 bytes header of a message containing the PM2.5 measurement
    static header_sn = bytes("160B1F") # 3 bytes header of a message containing the serial number
    static header_ver = bytes("160E1E") # 3 bytes header of a message containing the firmware version

    def init(raw_message)
        import persist
        self.debug = persist.find('pm1003_debugmode', false) # import debug mode flag from persistence or ignore if not exist.
        if raw_message == nil
            self.raw_message = bytes("012345")
        else
            self.raw_message = raw_message
        end
    end
    #-
    # return true if the message is valid, false otherwise
    -#
    def isvalid()
        return PM1003Message.validate(self.raw_message)
    end
    #-
    # static version of isvalid()
    -#
    static def validate(buffer)
        if !isinstance(buffer, bytes)
            return false # invalid type (not bytes)
        else
            var msg_error = PM1003Message.inspect(buffer)
            if msg_error == nil # valid message
                return true
            elif msg_error == 'err_empty_message'
                return false
            elif msg_error == 'err_not_bytes'
                return false
            elif msg_error == 'err_unknown_header'
                return false
            elif msg_error == 'err_checksum'
                return false
            else
                return false # another type of invalid message (sink)
            end
        end
    end
    #-
    # Inspect a message.
    -#
    static def inspect(msg)
        var header
        if !isinstance(msg, bytes) # check msg type
            # Exception: Message must be a bytes object.
            return 'err_not_bytes'
        elif msg == bytes('')   # check msg length
            # "Exception: The message is empty."
            return "err_empty_message"
        elif (msg[0..2] != PM1003Message.header_pm) &&
                (msg[0..2] != PM1003Message.header_sn) &&
                (msg[0..2] != PM1003Message.header_ver) # check header data
            # "Exception: Invalid message header."
            return "err_unknown_header"
        elif PM1003Message.checksum(msg) != 0 # verify checksum
                # "Exception: Invalid message checksum."
            return "err_checksum"
        else
            return nil # message is valid
        end
    end

    #-
    # Calculates the checksum of a message (sum of all bytes).
    -#
    static def checksum(msg)
        var cs = 0
        for i: 0..size(msg)-1
            cs += number(msg[i])
        end
        return cs % 256
    end

    #-
    # Process message for the serial number.
    -#
    def parse_serial_number(raw_message)
        var serial_str = ""
        serial_str += string.format("SN%04d.", number(raw_message[3])*256 + number(raw_message[4]))
        serial_str += string.format("%04d.", number(raw_message[5])*256 + number(raw_message[6]))
        serial_str += string.format("%04d.", number(raw_message[7])*256 + number(raw_message[8]))
        serial_str += string.format("%04d.", number(raw_message[9])*256 + number(raw_message[10]))
        serial_str += string.format("%04d", number(raw_message[11])*256 + number(raw_message[12]))
        print("Serial number: " + serial_str)
        return serial_str
    end

    #-
    # Process message for the PM2.5 measurement.
    -#
    def parse_pm(raw_message)
        var pm = number(raw_message[5])*256 + number(raw_message[6])
        if self.debug
            print("PM2.5: " + str(pm) + " μg/m³")
        end
        return pm
    end

    #-
    # Return the type of message.
    -#
    def type()
        var header = self.raw_message[0..2]
        if header == PM1003Message.header_pm
            return "pm"
        elif header == PM1003Message.header_sn
            return "sn"
        elif header == PM1003Message.header_ver
            return "ver"
        else
            return "invalid"
        end
    end

    #-
    # Return sensor data from message.
    -#
    def value()
        var type_msg = self.type()
        if  type_msg == "pm"
            return self.parse_pm(self.raw_message)
        elif type_msg == "sn"
            return self.parse_serial_number(self.raw_message)
        elif type_msg == "ver"
            return self.parse_firmware_version(self.raw_message)
        elif type_msg == "invalid"
            return nil
        else # unknown message type
            return nil
        end
    end
end

#-
# autotests for the class PM1003Message
-#
do
    assert(PM1003Message.inspect(bytes('')) == 'err_empty_message') # empty message
    assert(PM1003Message.inspect('abcd') == 'err_not_bytes') # not bytes object
    assert(PM1003Message.inspect(100) == 'err_not_bytes') # not bytes object
    assert(PM1003Message.inspect([10]) == 'err_not_bytes') # not bytes object
    assert(PM1003Message.inspect(bytes('abcdef')) == 'err_unknown_header') # unknown header
    assert(PM1003Message.inspect(bytes('16110B')) == 'err_checksum') # checksum = 0x32
    assert(PM1003Message.inspect(bytes('160B1FC0')) == nil) # 0x16 + 0x0B + 0x1F = 0xC0
    assert(PM1003Message.inspect(bytes('160E1EBE')) == nil) # 0x16 + 0x0E + 0xBE = 0xBD
end



#
# A berry driver for ESP32 to get data from a PM1003 particle sensor using serial communication.
#

class PM1003SerialComm : Driver
    var ser, counter_send, counter_read, counter_errors, retries, info, debug, message, sn, sensor_active, ver, pm, sn_timer
    def init()
        import persist
        self.debug = persist.find('pm1003_debugmode', false) # import debug mode flag from persistence or ignore if not exist.
        self.ser = serial(16, 17, 9600, serial.SERIAL_8N1) # USING UART2 pins: RX_GPIO = 16, TX_GPIO = 17, Baudrate = 9600, 8N1
        self.message = PM1003Message(bytes("00")) # store message object for debugging
        self.sn = "Levoit_pm1003"
        self.ver = "V0.0"
        self.info = map()
        self.retries = 0
        self.sensor_active = false
        self.counter_send = 0
        self.counter_read = 0
        self.counter_errors = 0
        self.sn_timer = 60 # period for requesting the serial number of the sensor
        self.pm = nil
    end
    def process_message(buffer)
        self.message = PM1003Message(buffer)
        if self.message.type() == 'pm'
            self.pm = self.message.value()
        elif self.message.type() == 'sn'
            self.sn = self.message.value()
        elif self.message.type() == 'ver'
            self.ver = "V"+ str(self.message.value())
        elif self.message.type() == 'unknown'
            #Do nothing
        end
        # empty cached message
    end

    def set_info(status, msg)
        self.info['status'] = status
        self.info['msg'] = msg
    end

    def get_json()
        self.info.setitem('online', self.sensor_active)
        self.info.setitem('counters', {'rx': self.counter_read, 'tx': self.counter_send, 'errors': self.counter_errors, 'retries': self.retries})
        self.info.setitem('raw_message', self.message.raw_message)
        self.info.setitem('localtime', tasmota.time_str(tasmota.rtc()['local']))
        self.info.setitem('utc', tasmota.time_str(tasmota.rtc()['utc']))
        if self.sensor_active == true
            # add pm measurement, serial number and software version:
            self.info.setitem('pm2.5', self.pm)
            self.info.setitem('sn', self.sn)
            self.info.setitem('ver', self.ver)
        else
            # remove pm, serial number and software version:
            self.info.remove('pm2.5')
            self.info.remove('serial')
            self.info.remove('version')
        end
        return self.info
    end

    ### Request the serial number from the sensor. ###
    def request_sn()
        var delay = 100
        self.send_message(PM1003Message.request_sn) # request serial number from sensor
        self.timer_for_delayed_respose(delay) # set a timer to get a delayed response:
    end
    ### Request the software version from the sensor. ###
    def request_ver()
        var delay = 300
        self.send_message(PM1003Message.request_ver) # request firmware version from sensor
        self.timer_for_delayed_respose(delay) # set a timer to get a delayed response:
    end
    ### Request the PM2.5 measurement from the sensor. ###
    def request_pm()
        var delay = 300
        self.send_message(PM1003Message.request_pm) # request pm data from sensor
        self.timer_for_delayed_respose(delay) # set a timer to get a delayed response:
    end
    ### Send message to sensor. ###
    def send_message(msg)
        self.counter_send += 1
        self.ser.flush() # flush the serial buffer just before sending.
        self.ser.write(msg) # request PM data to sensor
    end
    ### Delayed read response from buffer. ###
    def timer_for_delayed_respose(delay_ms)
        tasmota.set_timer(delay_ms, def() self.read_message() print("Reading") end) # set timer for delayed reading message from sensor
        # tasmota.set_timer(delay_ms, def() self.read_message() print("Reading... (" + str(self.counter_read) + ")") end) # set timer for delayed reading message from sensor
    end
    ### Read message from buffer. Returns True if available. ###
    def read_message()
        var buffer_size = self.ser.available()
        self.counter_read += 1
        var max_retries = 10
        if buffer_size > 0 # normal operation
            self.process_message(self.ser.read()) # read the message buffer, process it and store as Message object
            var msg = string.format("Normal operation, PM2.5 = %s  μg/m³.", self.pm)
            self.set_info("Online", msg)
            self.retries = 0
            self.sensor_active = true
            if self.debug
                print(msg)
            end
            return true
        elif self.retries <= max_retries  # retry to communicate with the sensor
            var msg = "No answer from PM1003 sensor, retrying " + str(self.retries) + "/" + str(max_retries) + " ..."
            self.counter_errors += 1
            self.set_info("Retrying", msg)
            self.retries += 1
            self.sensor_active = true
            if self.debug
                print(msg)
            end
            return false
        else # maximun of retries reached, sensor status is now offline.
            self.counter_errors += 1
            var msg = "PM1003 sensor offline."
            self.set_info("Offline", msg)
            self.retries = max_retries
            self.sensor_active = false
            if self.debug
                print(msg)
            end
            return false
        end
    end
    ### Pooling. ###
    def every_second()
        # at every second request pm
        # at every 60 seconds request sn
        # update status JSON
        self.request_pm() # request PM data from sensor
        if self.sn_timer == 0 # request SN each 60 seconds:
            tasmota.set_timer(300+200, def() self.request_sn() end) # delayed request the serial Number of the sensor
        end
        self.sn_timer = (self.sn_timer + 1) % 60
        if self.debug
            print(self.get_json().tostring())
        end
    end

    ## Publish data to MQTT. ##
    def publish()
        self.mqtt.publish("/levoit/pm2.5", self.pm) # publish the PM2.5 value to the MQTT broker
        self.mqtt.publish("/levoit/serial_number", self.sn) # publish the serial number to the MQTT broker
        self.mqtt.publish("/levoit/sensor_active", self.sensor_active) # publish the sensor active status to the MQTT broker
        self.mqtt.publish("/levoit/counter_send", self.counter_send) # publish the sent counter to the MQTT broker
        self.mqtt.publish("/levoit/counter_read", self.counter_read) # publish the read counter to the MQTT broker
        self.mqtt.publish("/levoit/counter_errors", self.counter_errors) # publish the errors counter to the MQTT broker
        self.mqtt.publish("/levoit/info", self.info) # publish the info to the MQTT broker
    end

    ## Display sensor value in the web UI. ###
    def web_sensor()
        if self.sensor_active == true
            var msg = string.format("{s}Levoit PM 2.5 {m}%d µg/m³{e}", self.pm)
            tasmota.web_send_decimal(msg)
        else
            var msg = string.format("{s}Levoit PM 2.5 {m}offline{e}") # sensor offline
            tasmota.web_send_decimal(msg)
        end
    end
    ## add sensor value to teleperiod ##
    def json_append()
        if self.sensor_active == true
            var msg = string.format(",\"%s\":{\"PM2.5\":%d,\"STATUS\":%s,\"MESSAGE\":%s}", self.sn, self.pm, self.info['status'], self.message.raw_message)
            tasmota.response_append(msg)
        else
            var msg = string.format(",\"%s\":{\"STATUS\":%s}", self.sn, self.info['status'])
            tasmota.response_append(msg)
        end
    end
end

return PM1003SerialComm() # allow using 'import' command instead of 'load()'
