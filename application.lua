local host = ""
local user = ""
local pass = ""

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
