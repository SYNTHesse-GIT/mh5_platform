# 2.8 Inch Touch Display MSP2834

The touch display MSP2834 is 2.8 inch SPI and uses ILI9341V controller. Touch is managed by FT6336G over I2C. Datasheet of the product is [here](http://www.lcdwiki.com/res/MSP2833_MSP2834/MSP2833_MSP2834_Specification_EN_V1.0.pdf).

## Display

At the moment there is no out of the box support in Raspberry Pi Debian for ILI9341V. Attempting to use the stock driver for ILI9341 would result in an image that is color inverse (blue is shown as yellow, red as magenta, etc.). To address this we use the `mipi-dbi-spi` driver with a custom bin.

The bin is obtained by "compling" a text init file included (ili9341v.txt) with the [mipi-dpi-cmd](https://github.com/notro/panel-mipi-dbi/blob/main/mipi-dbi-cmd) script. This creates a bin file that needs to be placed in `/lib/firmware/`. For convenience this repo includes a [install.sh](./install.sh) that does all this autmatically.

Once the bin is avaialable the `config.txt` will need to contain:

```
dtoverlay=mipi-dbi-spi,speed=36000000
dtparam=compatible=ili9341v\0panel-mipi-dbi-spi
dtparam=width=240,height=320,width-mm=43,height-mm=57
dtparam=reset-gpio=24,dc-gpio=25
```

Please note that the orientation will be portrait with the pin header on the lower side. The actual orientation control is given both by the 0x36 register in the init file (bin) as well as the `width` and `height` settings in the `config.txt`. Changing one without the other to match will result in images that are covering partially the screen.

## Touch

The display uses FT6336G touch controller over I2C. As there is no overlay that can be used we have a DTS that configures an overlay that deals with this. The overlay uses the FT6236 version of the driver and is expected to work over the i2c1 pins (GPIO2,3). Additionally uses GPIO 17 for interrupt and GPIO 27 for reset.

The DTS can be complied with:

```
dtc -I dts -O dtb -o ft6336g.dtbo ft6336g.dts
```

And should be copied to the `/boot/firmware/overlays/`:

```
sudo cp ft6336g.dtbo /boot/firmware/overlays/
```

The `install.sh` script will do that automatically.

In `/boot/firmware/config.txt` the overlay can be activated with:

```
dtoverlay=ft6336g
```