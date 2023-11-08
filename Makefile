CROSS_FLAGS = ARCH=arm CROSS_COMPILE=arm-none-eabi-
CROSS_FLAGS_BOOT = CROSS_COMPILE=aarm-none-eabi-

all: boot-asus-nexus7.img

kernel-asus-nexus7-grouper-e1565.gz-dtb: kernel-tegra30.gz dtbs/tegra30/tegra30-asus-nexus7-grouper-E1565.dtb
	cat kernel-tegra30.gz dtbs/tegra30/tegra30-asus-nexus7-grouper-E1565.dtb > $@

boot-%.img: initramfs-%.gz kernel-%.gz-dtb
	rm -f $@
	$(eval BASE := $(shell cat src/deviceinfo_$* | grep base | cut -d "\"" -f 2))
	$(eval SECOND := $(shell cat src/deviceinfo_$* | grep second | cut -d "\"" -f 2))
	$(eval KERNEL := $(shell cat src/deviceinfo_$* | grep kernel | cut -d "\"" -f 2))
	$(eval RAMDISK := $(shell cat src/deviceinfo_$* | grep ramdisk | cut -d "\"" -f 2))
	$(eval TAGS := $(shell cat src/deviceinfo_$* | grep tags | cut -d "\"" -f 2))
	$(eval PAGESIZE := $(shell cat src/deviceinfo_$* | grep pagesize | cut -d "\"" -f 2))
	mkbootimg --kernel kernel-$*.gz-dtb --ramdisk initramfs-$*.gz --base $(BASE) --second_offset $(SECOND) --kernel_offset $(KERNEL) --ramdisk_offset $(RAMDISK) --tags_offset $(TAGS) --pagesize $(PAGESIZE) --cmdline "console=tty1" -o $@

boot-%.img-debug: kernel-%.gz-dtb initramfs-%.gz
	rm -f $@
	$(eval BASE := $(shell cat src/deviceinfo_$* | grep base | cut -d "\"" -f 2))
	$(eval SECOND := $(shell cat src/deviceinfo_$* | grep second | cut -d "\"" -f 2))
	$(eval KERNEL := $(shell cat src/deviceinfo_$* | grep kernel | cut -d "\"" -f 2))
	$(eval RAMDISK := $(shell cat src/deviceinfo_$* | grep ramdisk | cut -d "\"" -f 2))
	$(eval TAGS := $(shell cat src/deviceinfo_$* | grep tags | cut -d "\"" -f 2))
	$(eval PAGESIZE := $(shell cat src/deviceinfo_$* | grep pagesize | cut -d "\"" -f 2))
	mkbootimg --kernel kernel-$*.gz-dtb --ramdisk initramfs-$*.gz --base $(BASE) --second_offset $(SECOND) --kernel_offset $(KERNEL) --ramdisk_offset $(RAMDISK) --tags_offset $(TAGS) --pagesize $(PAGESIZE) -o $@.img

%.img.xz: %.img
	@echo "XZ    $@"
	@xz -c $< > $@

initramfs/bin/busybox: src/busybox src/busybox_config
	@echo "MAKE  $@"
	@mkdir -p build/busybox
	@cp src/busybox_config build/busybox/.config
	@$(MAKE) -C src/busybox O=../../build/busybox $(CROSS_FLAGS)
	@cp build/busybox/busybox initramfs/bin/busybox

initramfs/bin/bash: src/bash
	@echo "MAKE  $@"
	@mkdir -p build/bash
	@cd build/bash;\
	../../src/bash/configure --host=arm-none-eabi- --enable-static-link --without-bash-malloc
	@$(MAKE) -C build/bash
	@arm-none-eabi-strip build/bash/bash
	@cp build/bash/bash initramfs/bin/bash
	
initramfs-%.cpio: initramfs/bin/bash initramfs/bin/busybox initramfs/init initramfs/init_functions.sh
	@echo "CPIO  $@"
	@rm -rf initramfs-$*
	@cp -r initramfs initramfs-$*
	@cp src/info-$*.sh initramfs-$*/info.sh
	@cp src/info-$*.sh initramfs-$*/info.sh
	@cd initramfs-$*; find . | cpio -H newc -o > ../$@
	
initramfs-%.gz: initramfs-%.cpio
	@echo "GZ    $@"
	@gzip < $< > $@
	
kernel-tegra30.gz: src/linux-tegra30
	@echo "MAKE  $@"
	@mkdir -p build/linux-tegra30
	@mkdir -p dtbs/tegra30
	@$(MAKE) -C src/linux-tegra30 O=../../build/linux-tegra30 $(CROSS_FLAGS) transformer_defconfig
	@$(MAKE) -C src/linux-tegra30 O=../../build/linux-tegra30 $(CROSS_FLAGS) -j $(nproc)
	@cp build/linux-tegra30/arch/arm/boot/zImage $@
	@cp build/linux-tegra30/arch/arm/boot/dts/tegra30-{asus-nexus7-grouper-*,asus-nexus7-tilapia-*}.dtb dtbs/tegra30/

dtbs/tegra30/tegra30-asus-nexus7-grouper-E1565.dtb: kernel-tegra30.gz

dtbs/tegra30/tegra30-asus-nexus7-grouper-PM269.dtb: kernel-tegra30.gz

dtbs/tegra30/tegra30-asus-nexus7-tilapia-E1565.dtb: kernel-tegra30.gz

src/linux-tegra30:
	@echo "Clone linux-tegra30"
	@mkdir src/linux-tegra30
	@git clone https://github.com/clamor-s/linux.git --depth=1 src/linux-tegra30	

src/busybox:
	@echo "WGET  busybox"
	@mkdir src/busybox
	@wget https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2
	@tar -xf busybox-1.36.1.tar.bz2 --strip-components 1 -C src/busybox

src/bash:
	@echo "WGET  bash"
	@mkdir src/bash
	@wget http://git.savannah.gnu.org/cgit/bash.git/snapshot/bash-5.2.tar.gz
	@tar -xvf bash-5.2.tar.gz --strip-components 1 -C src/bash

.PHONY: clean cleanfast

cleanfast:
	@rm -rvf build
	@rm -rvf initramfs-*/
	@rm -vf *.img
	@rm -vf *.img.xz
	@rm -vf *.tar.xz
	@rm -vf *.apk
	@rm -vf *.bin
	@rm -vf *.cpio
	@rm -vf *.gz
	@rm -vf *.gz-dtb
	@rm -rvf dtbs

# useful when debuging devicetree
cc:
	@rm -rvf initramfs-*/
	@rm -vf *.img
	@rm -vf *.gz
	@rm -vf *.gz-dtb
	@rm -rvf dtbs

clean: cleanfast
	@rm -vf kernel*.gz
	@rm -vf initramfs/bin/busybox
	@rm -vf initramfs/bin/bash
	@rm -vrf initramfs/lib
	@rm -vrf dtbs
