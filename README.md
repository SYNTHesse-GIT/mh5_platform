# mh5_hardware
Hardware setup instructions for MH5 robot based on Raspberry Pi CM4 and Waveshare Mini Base Board (B).

## OS install

First set the BOOT selection switch to OFF on the Mini Base Board. This will allow the installation of the OS on the eMMC. To flash the OS you have to use a PC or a Linux system (there are some problems with the rpiboot on MacOS). Here we will present the Windows instructions.

Download and install on the Windows machine the `rpi_boot` [installer](https://github.com/raspberrypi/usbboot/raw/master/win32/rpiboot_setup.exe). Once installed connect the Mini Base Board using the USB-C connector to the PC. Start the `RPiBoot.exe` application on the Windows machine (use the start menu). After the program runs the CM4 will appear as a drive in Windows.

Use the [`Raspberry Pi Imager`](https://www.raspberrypi.com/software/) tool and install the Raspberry Pi OS Liste (64-bit) version (you will find it in the Raspberry Pi OS (other) section. In the "CHOOSE STORAGE" use the drive that was installed by the `RPiBoot`. In the options (the gear button on the lower right) configure the following:

 - set hostname: mh5
 - enable SSH: yes (use password authentication)
 - set user name and password: mh5/robot
 - leave the WiFi unconfigured for the time being 

When the write is finished eject the drives from Windows and disconnedt the USB cable. Set the BOOT selection switch on the Mini Base Board to ON. Connect the board with an Ethernet cable, connect the fan, the extra WiFi dongle on USB and add the HAT board, including the TFT screen.

Start the board and use an IP scan tool to identify the IP address of the board. The device will be showing as `mh5.local` and the MAC Vendor should be Raspberry Pi Trading. 

Start a SSH session from you machine using the user `mh5` and password `robot` or whatever combination was chosen in the options when flashing the OS. Now we can configure the rest of the system.

## WiFi

We will configure the WiFi in routed mode: the on-board WiFi will produce a stand-alone AP (5GHz frequency, low latency) that you can use to connect to the robot from a remote system (ex. for controlling movement) and the second WiFi dongle (and the Ethernet port) will be configured to connect to an existing network (that you can update as needed when moving from one location to another) and the Raspberry Pi will route the traffic from one WiFi to another, so that you can still access Internet from the remote computer connected to the AP point (assuming the second WiFi or Ethernet is connected to a network and has Internet access).

### AP Configuration

Forst we will configure the AP on the inbuilt WiFi ([see also](https://www.raspberrypi.com/documentation/computers/configuration.html#software-install)).

Install software:
```
sudo apt install hostapd
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo apt install dnsmasq
sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent
```

Maintain configuration file:
```
sudo nano /etc/dhcpcd.conf
```
add in the file:
```
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
```
Enable Routing and IP Masquerading:
```
sudo nano /etc/sysctl.d/routed-ap.conf
```
and enter in the file:
```
# Enable IPv4 routing
net.ipv4.ip_forward=1
```
Configure firewall rules:
```
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o wlan1 -j MASQUERADE
```
And save them:
```
sudo netfilter-persistent save
```
Configure the DNS server:
```
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.conf
```
and enter in the file:
```
interface=wlan0 # Listening interface
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/gw.wlan/192.168.4.1
                # Alias for this router
```
Unblock the wlan0 interface:
```
sudo rfkill unblock wlan
```
And configure the AP settings:
```
sudo nano /etc/hostapd/hostapd.conf
```
and add the following:
```
country_code=GB
interface=wlan0
ssid=MH5
hw_mode=a
channel=44
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=RobotMH5
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```
This will setup an AP with name `MH5` and access password `RobotMH5`.

To activate all changes run:
```
sudo systemctl reboot
```

After reboot you should still be able to log on using the same SSH connection (if the cable is still connected) but this time you should also see the MH5 network being boradcast and you should be able to log on to it using the password above. If you're still connected with the Ethernet cable you should still have access to the Internet thanks to the routing software. Next we will get rid of the cables by configuring the second WiFi to connect to the avilable infrastructure.

### Connect wlan1

