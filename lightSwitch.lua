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
        -- send state to raspberry pi
        conn=net.createConnection(net.TCP, 0)
        conn:on("receive", function(conn, payload) print(payload) end )
        conn:on("connection", function(conn,payload)
             print("sending...")
             if isOn then
                conn:send("GET /putEvent?r=0&t=light&v=1 / HTTP/1.0\r\n") 
             else
                conn:send("GET /putEvent?r=0&t=light&v=0 / HTTP/1.0\r\n") 
             end
             conn:send("Accept: */*\r\n") 
             conn:send("User-Agent: Mozilla/4.0 (compatible; ESP8266;)\r\n") 
             conn:send("\r\n") 
        end)
        conn:connect(8000,"192.168.178.46")
    end
end

switch(false)
-- when the interrupt is triggerd, wait 50ms and check whether the button is actually pressed
gpio.trig(pinButton, "down",function() tmr.alarm(0,50,0,button) end)

srv = net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(conn, payload)
        print("cmd")
        if string.find(payload, "GET /ON") then
            switch(true)
        elseif string.find(payload, "GET /OFF") then
            switch(false)
        end
        if isOn then txt ="ON" else txt = "OFF" end
        conn:send("HTTP/1.1 200 OK\r\n\r\n")
        conn:send("<html>")
        file.open("_control.html", "r")
        repeat
            local line=file.read(128)
            if line then conn:send(line)end
        until not line 
        file.close()
        conn:send("<i>current state:" .. txt .. "</i>")
        conn:send("</html>")
        conn:close()
    end)
end)
