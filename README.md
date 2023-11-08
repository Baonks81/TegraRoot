# TegraRoot
Testing mainline kernel for Tegra3 T30L

A simple initramfs builder for TegraKexec, currently supporting:

- Asus Google Nexus 7 wifi - grouper rev.PM269 (Not Tested)
- Asus Google Nexus 7 wifi - grouper rev.E1565 (Not Tested)
- Asus Google Nexus 7 wifi - tilapia rev.E1565 (Not Tested)

### Tegra Devices Usage

Boot the image using `fastboot boot`.

### Building

The dependencies are:

Additional dependencies for Tegra(Qualcomm method) Devices:
- mkbootimg

```shell-session

$ make -j8 boot-asus-nexus7.img
Builds everything needed for the pinephone image...

$ make -j8 all
Generates an image for every supported platform in parallel

$ fastboot boot boot-asus-nexus7.img
Let TegraKexec Rock in Your Tablet!

$ fastboot flash boot boot-asus-nexus7.img
Install TegraKexec to your tablet!

```

### This project is built on:
- [Busybox](https://busybox.net) - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [postmarketOS](https://postmarketos.org) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- [JumpDrive](https://github.com/dreemurrs-embedded/Jumpdrive) scripts - which is [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).

