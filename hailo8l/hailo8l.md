# Hailo8L Accelerator

## Install Code

The instructions are provided in the [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/ai.html#hardware-setup) and are summarized here:

Configure the PCI for gen3:

```
$ sudo nano /boot/firmware/config.txt
```
and add:
```
dtparam=pciex1_gen=3
```
It is also posible to configure this in `raspi-config` under *Advanced Options -> PCIe Speed -> Enable PCIe gen 3*.


Install all the required drivers, and applications:

```
$ sudo apt install hailo-all
```
Reboot and check that the board is recognized:
```
$ hailortcli fw-control identify
```
A response similar to the one below should be returned:
```
Executing on device: 0000:01:00.0
Identifying board
Control Protocol Version: 2
Firmware Version: 4.17.0 (release,app,extended context switch buffer)
Logger Version: 0
Board Name: Hailo-8
Device Architecture: HAILO8L
Serial Number: HLDDLBB234500054
Part Number: HM21LB1C2LAE
Product Name: HAILO-8L AI ACC M.2 B+M KEY MODULE EXT TMP
```
