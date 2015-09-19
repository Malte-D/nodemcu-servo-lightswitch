pinButton = 2
pinLed = 4
pinServo = 6 -- GPIO 12

servoPosOn = 75
servoPosOff = 50

gpio.mode(pinLed,gpio.OUTPUT)
gpio.mode(pinButton,gpio.INT,gpio.PULLUP)

function switch(on)
    isOn = on
    print("on:")
    print(isOn)
    if isOn then 
        pwm.setup(pinServo,50,servoPosOn)
        gpio.write(pinLed,gpio.LOW)
    else 
        pwm.setup(pinServo,50,servoPosOff)
        gpio.write(pinLed,gpio.HIGH)
    end
    pwm.start(pinServo)
    tmr.alarm(1,500,0,function() pwm.stop(pinServo) end)
end

function button()
    if gpio.read(pinButton) == 0 then
        switch(not isOn)
    end
end

switch(false)
-- when the interrupt is triggerd, wait 50ms and check whether the button is actually pressed
gpio.trig(pinButton, "down",function() tmr.alarm(0,50,0,button) end)

srv = net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(conn, payload)
        if string.find(payload, "GET /ON") then
            switch(true)
        elseif string.find(payload, "GET /OFF") then
            switch(false)
        end
        if isOn then txt ="ON" else txt = "OFF" end
        local response = "HTTP/1.1 200 OK\r\n\r\n<h2><a href=\"ON\">ON</a><br><a href=\"OFF\">OFF</a><br></h2><i>current state: " .. txt .. "</i>"
        conn:send(response, function()
            conn:close()
        end)
    end)
end)