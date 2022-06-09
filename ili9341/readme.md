compile the `dts`:

```
dtc -I dts -O dtb -o mh5-display.dtbo mh5-display.dts
sudo cp mh5-display.dtbo /boot/overlays/
```

add this in /boot/config.txt

```
dtoverlay=mh5-display,speed=25000000,fps=20
```

add this in /boot/cmdline.txt:

```
console=serial0,115200 console=tty1 root=PARTUUID=ed2c2edf-02 rootfstype=ext4 fsck.repair=yes rootwait fbcon=map:10 fbcon=font:VGA8x8
```

run `sudo dpkg-reconfigure console-setup` and configure:

  1. utf-8
  2. Guess optimal character set
  3. Terminus
  4. 6x12

reboot; you should be able to see the console on display
