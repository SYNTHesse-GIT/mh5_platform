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

To access a WiFi network you only need to enter the details in the `/etc/wpa_supplicant/wpa_supplicant.conf`, but if you would like not to have the password in clear the best is to encrypt the password using `wpa_passphrase`, like this:
```
wpa_passphrase "<SSID>" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
```
Replace SSID with the name of the WiFi you want to associate with and enter the passphrase. The `wpa_passphrase` will store the access details in the conf file. Please note that both the encrypted and the clear password will be storred there, so you should then run:
```
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```
and remove the clear password from the file.

If you want to connect directly use now:
```
wpa_cli -i wlan1 reconfigure
```
To see the status of your connections run:
```
ifconfig
```
All interfaces should be connected. You can now disconnect the Ethernet cable.

## Hardware interfaces

### TFT Display

We will start with the TFT display. First get into the `ili9341` directory and then compile the device tree overlay. The driver for the ili9341 is already included in the standard kernel, but the exisiting overlays are not configured in the same way as the TFT used in MH5.
```
dtc -I dts -O dtb -o mh5-display.dtbo mh5-display.dts
```
And copy it in the `/boot/overlays` directory:
```
sudo cp mh5-display.dtbo /boot/overlays/
```
To be used, we need to update the `config.txt` file:
```
sudo nano /boot/config.txt
```
and enter at the end after `[all]`:
```
dtparam=spi=on
dtparam=i2c1=on
dtparam=i2c_arm=on
dtoverlay=mh5-display,speed=25000000,fps=20
```
To activate the console add the following in `/boot/cmdline.txt`:
```
sudo nano /boot/cmdline.txt
```
and add:
```
fbcon=map:10 fbcon=font:VGA8x8
```
after the `rootwait` with oobly one space after that to `fbcon`. You can now reboot the machine:
```
sudo systemctl reboot
```
While booting the system messages should start being displayed on the screen and after that the console prompt will be shown. If using a Bluetooth keyboard you should be able to enter commands directly.

To change the font size to a more readable one use:
```
sudo dpkg-reconfigure console-setup
```
and chooe: utf-8 -> Guess optimal character set -> Terminus -> 6x12

### Dynamixel bus

To activate the drivers for SC16IS762 chip you need to compile and deploy the device tree overlay and update the `config.txt` file. First go to the `sc16is7xx`directory. Compile the dts:
```
dtc -I dts -O dtb -o sc16is762-spi0-ce1.dtbo sc16is762-spi0-overlay.dts 
```
The existing overlays for SC16IS7XX are not suitable because they only assume CE0 either for SPI0 or SPI1. We use SPI0, but we have a separate CE1 pin that we configure in this overlay. Also, we configure a higher communictation speed because we are using a higher frequency crystal on the board. Then copy the dtbo to the `/boot/overlays`:
```
sudo cp sc16is762-spi0-ce1.dtbo /boot/overlays/
```
Activate the interface by including this in the `config.txt`:
```
dtoverlay=sc16is762-spi0-ce1
```
(you can add it after the `mh5-display` one.)
Reboot the system (`sudo systemctl reboot`) and check after logging in that two new `tty` ports are shown:
```
ls /dev/ttySC*
```
### Fan

(This doesn't work well with the 3 wire 4010 fan).

The fan drivers need `dkms`. Frist install this:
```
sudo apt install dkms
sudo apt install raspberrypi-kernel-headers
```
(for some reasons the installation of dkms picks older 5.10 headers which are fixed with the next install.

Then install:
```
git clone https://github.com/neg2led/cm4io-fan.git
cd cm4io-fan
sudo chmod 777 install.sh
sudo ./install.sh
```

## Software

### Mambaforge

In the mh5 home directory get the lateast installer for miniforge:
```
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh
```
Change the access and run the installer:
```
chmod +x Miniforge3-Linux-aarch64.sh
./Miniforge3-Linux-aarch64.sh
```
Accept the defaults and the installer finish. Indicate to run conda init at the end. Exit your ssh session and relog (this will activate the conda environment).

No install mamba (it's faster and works better with large environments like ours). This is done only once in the (base) environment.
```
conda install mamba -c conda-forge
```

### Setup a ROS environment

Now we use mamba to setup a new environment that will install packages from ros-noetic-robot.
```
mamba create -n rs ros-noetic-robot python=3.9 -c robostack -c robostack-experimental -c conda-forge --no-channel-priority --override-channels
```
You can now activate the environment:
```
conda activate rs
```
And install a few other things needed for development:
```
mamba install compilers cmake pkg-config make ninja
mamba install catkin_tools
mamba install rosdep
```
Deactivate and reactivate the environment:
```
conda deactivate
conda activate rs
```
And initialize `rosdep`:
```
rosdep init
rosdep update
```
Create a project directory in the home of `mh5`:
```
cd
mkdir -p catkin_ws/src
cd catkin_ws
catkin build
```
Now you're ready to go with the ROS! Any custom packages can be added to `~/catkin_ws/src` while standard ROS packages (if avaialble for `aarch` and python 3.9 can be installed with `mamba install ros-noetic-<package-name-with-dashes>`. Don't forget to `ssource devel/setup.bash` before using your packages. Better add this in the `~/.bashrc`. You should also add `conda activate rs` in case this is the default environment that you use on the robot.

### MH5 ROS packages

We need this for catkin to find `gtest`:
```
sudo apt-get install libgtest-dev
sudo apt-get install libi2c-dev
```

Install dependent packages:
```
mamba install -c robostack ros-noetic-image-transport ros-noetic-cv-bridge ros-noetic-camera-info-manager ros-noetic-roslint ros-noetic-realtime-tools ros-noetic-control-toolbox ros-noetic-dynamixel-sdk ros-noetic-resource-retriever
```
(These ones need to be updated in RoboStack):
```
ros_control
ros_controllers
cv_camera
four_wheel_steering_msgs
urdf_geometry_parser
```

Now install ROS packages for MH5:
```
cd ~/catkin_ws/src
git clone https://github.com/SYNTHesse-GIT/mh5_common
git clone https://github.com/SYNTHesse-GIT/mh5_robot
git clone https://github.com/SYNTHesse-GIT/mh5_behaviour
cd ..
catkin build
```
