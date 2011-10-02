## ANT+ HRM Data over a Websocket

This code uses the 'hrm' executable in https://github.com/joewilliams/antplus_hrm0_5 to communicate with a Garmin ANT+ USB Stick and capture heart rate data from a Garmin HRM. 

### Install

	git clone git://github.com/joewilliams/antplus_hrm0_5.git
	cd antplus_hrm0_5
	make

	cd ..

	git clone git://github.com/joewilliams/antplus_websockets.git
	cd antplus_websockets
	./rebar get-deps compile generate
	mkdir rel/antplus_websockets/lib/antplus_websockets-0.1/priv
	cp ../antplus_hrm0_5/hrm rel/antplus_websockets/lib/antplus_websockets-0.1/priv/
	./rel/antplus_websockets/bin/antplus_websockets console

Now hit localhost:8080 in a browser you should see output like the following.

	{"data":{"hrm":53.94210000000000349}}
	{"data":{"hrm":55.803800000000002512}}
	{"data":{"hrm":57.100400000000000489}}

This has been tested on Ubuntu 10.04.

### Misc

If you plug in the USB stick and ttyUSB0 doesn't show up, try the following and reconnect it:

	sudo modprobe usbserial
