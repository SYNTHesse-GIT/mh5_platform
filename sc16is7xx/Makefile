KERNELDIR=/lib/modules/`uname -r`/build

MODULES = sc16is7xx.ko
obj-m += sc16is7xx.o

all:
	make -C $(KERNELDIR) M=$(PWD) modules

clean:
	make -C $(KERNELDIR) M=$(PWD) clean

install:
	make -C $(KERNELDIR) M=$(PWD) modules_install

quickInstall:
	cp $(MODULES) /lib/modules/`uname -r`/extra
