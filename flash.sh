
MCU=t13a
file=./build/Debug/avr_dashboard_resetter.hex

#avrdude -c usbtiny -p m168 -U flash:w:./build/Debug/serialLoopback.hex
avrdude -c usbasp -p $MCU -B 64kHz -U flash:w:${file}
