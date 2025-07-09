./mipi-dbi-cmd ili9341v.bin ili9341v.txt
sudo cp ili9341v.bin /lib/firmware/
./mipi-dbi-cmd /lib/firmware/ili9341v.bin

dtc -I dts -O dtb -o ft6336g.dtbo ft6336g.dts
sudo cp ft6336g.dtbo /boot/firmware/overlays/
