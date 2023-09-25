local mqtt_host = ""
local mqtt_user = ""
local mqtt_pass = ""

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

local power_state = 0			-- 0 off, 1 on, 2 standby

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

function init_pins()
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

function fan(level)
	level = level or 0				-- default value
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

function connect_mqtt()
    m:connect(mqtt_host, 1883, false, function(client)
		print("Connected")
		client:publish("conditioner/state", "online", 0, 0)
		client:subscribe("conditioner/state", 0)
    end,
	function(client, reason)
		print("Connection failed reason: " .. reason)
	end)
end

function drain_pump_loop()
	if power_state > 0 then
		if drain_level > 0 then
			drain_pump_on()
		else
			drain_pump_off()
		end
	else
		drain_pump_off()
	end
end

function mqtt_send_loop()
	m:publish("conditioner/air_inlet", air_in_temp, 0, 0)
	if fan_level > 0 then
		m:publish("conditioner/air_outlet", air_out_temp, 0, 0)
	end
	if water_valve_pin == 1 then
	    m:publish("conditioner/water_inlet", water_in_temp, 0, 0)
	    m:publish("conditioner/water_outlet", water_out_temp, 0, 0)
	end
end

function main_loop()
	if power_state == 0 then
		water_valve_off()
		fan_level = 0
		fan(fan_level)
	elseif power_state == 1 then
		if air_in_temp <= air_set_temp then
			if fan_level > 0 then
				fan_level = fan_level - 1
				water_valve = 1
			else
				water_valve = 0
			end
		elseif air_in_temp > air_set_temp then
			water_valve = 1
			if fan_level < 3 then
				fan_level = fan_level + 1
			end
		end
		fan(fan_level)
		if water_valve == 1 then
			water_valve_on()
		else
			water_valve_off()
		end
	elseif power_state == 2 then
	end
end

m = mqtt.Client("conditioner", 120, mqtt_user, mqtt_pass)

m:lwt("/lwt", "offline", 0, 0)

m:on("offline", function(client) -- restart connection in any case
	m:close()
	print ("Disconnected")
	tmr.create():alarm(2000, tmr.ALARM_SINGLE, connect_mqtt) -- in a couple of seconds
end)

m:on("message", function(client, topic, data)
	if topic == "conditioner/state" then
	    if data == "on" then
		    power_state = 1
        elseif data == "off" then
			power_state = 0
		else
			power_state = 2
    	end
	elseif topic == "conditioner/set_temp" then
		air_set_temp = data
	end
end)

init_pins()
connect_mqtt()

tmr.create():alarm(60000, tmr.ALARM_AUTO, mqtt_send_loop) 	-- every 60 seconds
tmr.create():alarm(120000, tmr.ALARM_AUTO, main_loop) 		-- every 120 seconds
tmr.create():alarm(3000, tmr.ALARM_AUTO, drain_pump_loop)	-- every 3 seconds
