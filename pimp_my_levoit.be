# Limits on Levoit:
# Blue : pm < 70 µg/m3
# Green : 100 µg/m3 > pm >= 70 µg/m3
# Yellow : 130 µg/m3 > pm >= 100 µg/m3
# Red : pm > 130 µg/m3

#-
 - Example of PM1003 driver written in Berry
 - By Fabio Manzoni
-#

import string
class Message
    var msg_bytes, debug

    # patterns for request message:
    static request_pm = bytes("11020B01E1") # message pattern to request the PM2.5 measurement
    static request_sn = bytes("11011FCF") # message pattern to request the serial number
    static request_ver = bytes("11011ED0") # message pattern to request the firmware version
    # patterns of sensor responses header (first 3 bytes of the message):
    static header_pm = bytes("16110B") # 3 bytes header of a message containing the PM2.5 measurement
    static header_sn = bytes("160B1F") # 3 bytes header of a message containing the serial number
    static header_ver = bytes("160E1E") # 3 bytes header of a message containing the firmware version

    def init(msg_bytes)
        self.debug = true
        self.msg_bytes = msg_bytes
    end
    #-
    # return true if the message is valid, false otherwise
    -#
    def isvalid()
        return Message.validate(self.msg_bytes)
    end
    #-
    # static version of isvalid()
    -#
    static def validate(buffer)
        if !isinstance(buffer, bytes)
            return false
        else
            var ans = Message.inspect(buffer)
            if ans != nil
                if ans == 'err_empty_message'
                    return false
                elif ans == 'err_not_bytes'
                    return false
                elif ans == 'err_unknown_header'
                    return false
                elif ans == 'err_checksum'
                    return false
                else
                    return true # valid message
                end
            else # ans is nil
                return false
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
    def parse_serial_number(msg_bytes)
        var serial_str = ""
        serial_str += string.format("%04d,", number(msg_bytes[3])*256 + number(msg_bytes[4]))
        serial_str += string.format("%04d,", number(msg_bytes[5])*256 + number(msg_bytes[6]))
        serial_str += string.format("%04d,", number(msg_bytes[7])*256 + number(msg_bytes[8]))
        serial_str += string.format("%04d,", number(msg_bytes[9])*256 + number(msg_bytes[10]))
        serial_str += string.format("%04d.", number(msg_bytes[11])*256 + number(msg_bytes[12]))
        print("Serial number: " + serial_str)
        return serial_str
    end

    #-
    # Process message for the PM2.5 measurement.
    -#
    def parse_pm(msg_bytes)
        var pm = number(msg_bytes[3])*256 + number(msg_bytes[4])
        if self.debug
            print("PM2.5: " + str(pm) + " μg/m³")
        end
        return pm
    end

    #-
    # Return the type of message.
    -#
    def type()
        var header = self.msg_bytes[0..2]
        if header == Message.header_pm
            return "pm"
        elif header == Message.header_sn
            return "sn"
        elif header == Message.header_ver
            return "ver"
        else
            return "unknown"
        end
    end

    #-
    # Return sensor data from message.
    -#
    def value()
        var type_msg = self.type()
        if  type_msg == "pm"
            return self.parse_pm(self.msg_bytes)
        elif type_msg == "sn"
            return self.parse_serial_number(self.msg_bytes)
        elif type_msg == "ver"
            return self.parse_firmware_version(self.msg_bytes)
        else # unknown message type
            print("Unknown message type.")
            return ""
        end
    end
end





#-
# autotests for the class Message
-#
do
    assert(Message.inspect(bytes('')) == 'err_empty_message') # empty message
    assert(Message.inspect('abcd') == 'err_not_bytes') # not bytes object
    assert(Message.inspect(100) == 'err_not_bytes') # not bytes object
    assert(Message.inspect([10]) == 'err_not_bytes') # not bytes object
    assert(Message.inspect(bytes('abcdef')) == 'err_unknown_header') # unknown header
    assert(Message.inspect(bytes('16110B')) == 'err_checksum') # checksum = 0x32
    assert(Message.inspect(bytes('160B1FC0')) == nil) # 0x16 + 0x0B + 0x1F = 0xC0
    assert(Message.inspect(bytes('160E1EBE')) == nil) # 0x16 + 0x0E + 0xBE = 0xBD
end





class PM1003Sensor : Driver
    var ser, counter_send, counter_read, counter_errors, retries, info, debug, buffer, message, sn, sensor_active
    def init()
        self.debug = false # flag to enable/disable debug messages
        self.buffer = bytes('') # buffer for incoming messages
        self.ser = serial(16, 17, 9600, serial.SERIAL_8N1) # USING UART2 pins: RX_GPIO = 16, TX_GPIO = 17, Baudrate = 9600, 8N1
        self.message = Message() # message object to store incoming messages
        self.sn = "Levoit_pm1003"
        self.info = {'status' : 'msg'}
        self.set_info('Powering on', 'Starting sensor...') # set status info
        self.retries = 0
        self.sensor_active = false
        self.counter_send = 0
        self.counter_read = 0
        self.counter_errors = 0
    end
    def set_info(status, msg)
        # log status:
        self.info['status'] = status
        self.info['msg'] = msg
    end
    def pm_value()
        if self.message.type() == "pm"
            return self.message.value()
        else
            return 9999
        end
    end
    ### Request the serial number from the sensor. ###
    def request_sn()
        self.send_message(Message.request_sn) # request serial number from sensor
    end
    ### Request the software version from the sensor. ###
    def request_ver()
        self.send_message(Message.request_ver) # request firmware version from sensor
    end
    ### Request the PM2.5 measurement from the sensor. ###
    def request_pm()
        self.send_message(Message.request_pm) # request pm data from sensor
    end
    ### Send message to sensor. ###
    def send_message(msg)
        self.counter_send += 1
        self.ser.flush() # flush the serial buffer just before sending.
        self.ser.write(msg) # request PM data to sensor
    end
    ### Read message from buffer. Returns True if available. ###
    def read_message()
        var buffer_size = self.ser.available()
        var max_retries = 10
        self.counter_read += 1
        if buffer_size > 0 # normal operation
            self.message = Message(self.ser.read()) # read the message and store as Message object
            self.set_info("Online", "Normal operation.")
            self.retries = 0
            self.sensor_active = true
            return true
        elif self.retries <= max_retries  # retry operation
            self.counter_errors += 1
            self.message = Message(bytes('')) # no message available
            self.set_info("Retrying", "No answer from PM1003 sensor, retrying " + str(self.retries) + "/" + str(max_retries) + " ...")
            self.retries += 1
            self.sensor_active = true
            return false
        else # maximun of retries reached
            self.counter_errors += 1
            self.message = Message(bytes('')) # no message available
            self.set_info("Offline", "PM1003 sensor not available.")
            self.retries = max_retries
            self.sensor_active = false
            return false
        end
    end

    ### Pooling. ###
    def every_second()
        self.request_pm() # request PM data from sensor
        tasmota.set_timer(800, def() self.read_message() print("Reading... (" + str(self.counter_read) + ")") end) # set timer for delayed reading message from sensor
    end

    ### Publish data to MQTT. ###
    def publish()
        self.mqtt.publish("/levoit/pm2.5", self.pm_value()) # publish the PM2.5 value to the MQTT broker
        self.mqtt.publish("/levoit/serial_number", self.sn) # publish the serial number to the MQTT broker
        self.mqtt.publish("/levoit/sensor_active", self.sensor_active) # publish the sensor active status to the MQTT broker
        self.mqtt.publish("/levoit/counter_send", self.counter_send) # publish the sent counter to the MQTT broker
        self.mqtt.publish("/levoit/counter_read", self.counter_read) # publish the read counter to the MQTT broker
        self.mqtt.publish("/levoit/counter_errors", self.counter_errors) # publish the errors counter to the MQTT broker
        self.mqtt.publish("/levoit/info", self.info) # publish the info to the MQTT broker
    end

    ### Display sensor value in the web UI. ###
    def web_sensor()
        if self.sensor_active == true
            var msg = string.format("{s}Levoit PM 2.5 {m}%d µg/m³{e}", self.pm_value())
            tasmota.web_send_decimal(msg)
        else
            var msg = string.format("{s}Levoit PM 2.5 {m}offline{e}") # sensor offline
            tasmota.web_send_decimal(msg)
        end
    end
    #- add sensor value to teleperiod -#
    def json_append()
        if self.sensor_active == true
            var msg = string.format(",\"%s\":{\"PM2.5\":%d,\"STATUS\":%s,\"MESSAGE\":%s}", self.sn, self.pm_value(), self.info['status'], self.message.msg_bytes)
            tasmota.response_append(msg)
        else
            var msg = string.format(",\"%s\":{\"STATUS\":%s}", self.sn, self.status)
            tasmota.response_append(msg)
        end
    end
end

pm_sensor = PM1003Sensor()
tasmota.add_driver(pm_sensor)

# copy next line at the berry console to remove the driver:
# tasmota.remove_driver(pm_sensor)
