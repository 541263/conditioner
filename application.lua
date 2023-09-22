local host = ""
local user = ""
local pass = ""

-- 0	GPIO16
-- 1	GPIO5
-- 2	GPIO4
-- 3	GPIO0
-- 4	GPIO2
-- 9	GPIO3
-- 10	GPIO1
-- 11	GPIO9
local fan_level1_pin = 5		-- 5	GPIO14
local fan_level1_pin = 6		-- 6	GPIO12
local fan_level1_pin = 7		-- 7	GPIO13
local water_valve_pin = 8		-- 8	GPIO15
local drain_pump_pin = 12		-- 12	GPIO10

local air_in_temp = 0
local air_out_temp = 0
local air_delta = 0
local air_set_temp = 0
local drain_level = 0
local water_in_temp = 0
local water_out_temp = 0
local water_delta = 0
local water_valve = 0
local drain_pump = 0
local fan_level = 0

function initpins()
	gpio.mode(drain_pump_pin, gpio.OUTPUT)
	gpio.mode(water_valve_pin, gpio.OUTPUT)
	gpio.mode(fan_level1_pin, gpio.OUTPUT)
	gpio.mode(fan_level2_pin, gpio.OUTPUT)
	gpio.mode(fan_level3_pin, gpio.OUTPUT)
end

function water_valve_on()
	gpio.write(water_valve_pin, gpio.HIGH)
end

function water_valve_off()
	gpio.write(water_valve_pin, gpio.LOW)
end

function drain_pump_on()
	gpio.write(drain_pump_pin, gpio.HIGH)
end

function drain_pump_off()
	gpio.write(drain_pump_pin, gpio.LOW)
end

function fan_level(level=0)
	if level == 1 then
		gpio.write(fan_level1_pin, gpio.HIGH)
		gpio.write(fan_level2_pin, gpio.LOW)
		gpio.write(fan_level3_pin, gpio.LOW)
	elseif level == 2 then
		gpio.write(fan_level1_pin, gpio.HIGH)
		gpio.write(fan_level2_pin, gpio.HIGH)
		gpio.write(fan_level3_pin, gpio.LOW)
	elseif level == 3 then
		gpio.write(fan_level1_pin, gpio.HIGH)
		gpio.write(fan_level2_pin, gpio.HIGH)
		gpio.write(fan_level3_pin, gpio.HIGH)
	else
		gpio.write(fan_level1_pin, gpio.LOW)
		gpio.write(fan_level2_pin, gpio.LOW)
		gpio.write(fan_level3_pin, gpio.LOW)
	end
end





m = mqtt.Client("conditioner", 120, user, pass)

m:lwt("/lwt", "offline", 0, 0)

m:on("offline", function(client) -- restart connection in any case
		m:close()
		print ("Disconnected")
        tmr.create():alarm(2000, tmr.ALARM_SINGLE, connect) -- in a couple of seconds
	end)

m:on("message", function(client, topic, data)
		if topic == "sm/state" then
		    if data == "on" then
			      commandOn()
        elseif data == "off" then
			      commandOff()
        end
		end
	end)

function connect()
    m:connect(host, 1883, false, function(client)
            print("Connected")
            client:publish("sm/state", "online", 0, 0)
            client:subscribe("sm/state", 0)
        end,
        function(client, reason)
            print("Connection failed reason: " .. reason)
        end)
end

function loop()
    -- collect some data and send it
    m:publish("sm/temp", "20.5", 0, 0)
end

connect()

tmr.create():alarm(60000, tmr.ALARM_AUTO, loop) -- every 60 seconds
