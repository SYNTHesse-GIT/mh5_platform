# Camera Configuration

## MH5 Rev G

Revision G of Miha includes 2 CSI OV5647 cameras with 120 degrees FOV connected to the Raspberry Pi 5. To configure the cameras for use in ROS packages make the following changes in `/boot/firmware/config.txt`:

```
# change the camera auto detection and add the explicit overlays for OV5647
# we also configure here the orientation, as the cameras are mounted
# upside down
camera_auto_detect=0
dtoverlay=ov5647,cam0,rotation=180
dtoverlay=ov5647,cam1,rotation=180
```
The cameras use `libcamera` that should be installed automatically with the system. Also Raspberry Pi camera apps should also come pre-installed.

You can validate that the cameras are visible to the following command:
```bash
(ros2) mh5@mh5g:~/mh5_ws $ rpicam-hello --list-cameras
Available cameras
-----------------
0 : ov5647 [2592x1944 10-bit GBRG] (/base/axi/pcie@120000/rp1/i2c@88000/ov5647@36)
    Modes: 'SGBRG10_CSI2P' : 640x480 [58.92 fps - (16, 0)/2560x1920 crop]
                             1296x972 [46.34 fps - (0, 0)/2592x1944 crop]
                             1920x1080 [32.81 fps - (348, 434)/1928x1080 crop]
                             2592x1944 [15.63 fps - (0, 0)/2592x1944 crop]

1 : ov5647 [2592x1944 10-bit GBRG] (/base/axi/pcie@120000/rp1/i2c@80000/ov5647@36)
    Modes: 'SGBRG10_CSI2P' : 640x480 [58.92 fps - (16, 0)/2560x1920 crop]
                             1296x972 [46.34 fps - (0, 0)/2592x1944 crop]
                             1920x1080 [32.81 fps - (348, 434)/1928x1080 crop]
                             2592x1944 [15.63 fps - (0, 0)/2592x1944 crop]
```

