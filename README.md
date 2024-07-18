This project is fork from zoltanvb's https://github.com/zoltanvb/retroarch-cross-compile, I made some changes to adapt to my needs.

  * Containerfile more compatible with podman
  * Compile to cores to Trimui Smart Pro
  * Remove crosstool

# retroarch-cross-compile podman compatible 

Container image configurations to enable cross-compilation of retroarch and libretro cores, where host is a generic x86-64 machine, and target is the trimui smart pro hndheld.

# arm64-xenial
Image that can compile Retroarch and libretro cores for ARM

## Building the image
`cd arm64-xenial`
`sudo podman build --log-level=debug --squash --ulimit nofile=2048:2048 -f Containerfile -t arm64-focal:latest` 


Note that build process will take a while (up to one hour), as it will include building a complete toolchain with crosstools-ng.

Update for 2023-09: some packages have disappeared from xenial repositories, so libmpv and libsdl2 is now excluded from building.

## Using the image to build retroarch / cores
Clone the repository to build (RetroArch, individual core, or even libretro-super), then:
`sudo podman run --rm -it -v "<cloned dir>:/build" <image name>`

ex:
`sudo podman run --rm -it -v ".:/developer:Z" localhost/arm64-focal:latest`

`cd /build`
Anything that you put under /build, will be preserved after you exit the container, others will be permanently lost.

### Building RetroArch
`./configure --host=aarch64-linux-gnu`  
`make -j <CPU count of your builder machine>`  
Note that there is no sense in doing "make install" inside the container. You will have the binary, but you can't execute it on your x86_64 host. But you can transfer the resulting binary to your ARM system, and run it there.

### Building cores with libretro-super
`export JOBS=<CPU count of your builder machine>`
export CFLAGS="-mcpu=cortex-a53 -mtune=cortex-a53 -O3"
`export platform=linux-arm64`  
`./libretro-fetch.sh <core name>`  
`./libretro-build.sh <core name>`  
Note that this will produce a binary .so compiled with `platform=unix-armv8-hardfloat-neon`. Compiled library will be copied to `dist/unix`.

### building recipes (my fork of libreto-super)
sudo podman run --rm -it -v ".:/developer:Z" localhost/arm64-xenial:latest
export JOBS=<CPU count of your builder machine>
export CFLAGS="-mcpu=cortex-a53 -mtune=cortex-a53 -O3"
export CC=/usr/bin/aarch64-linux-gnu-gcc-
export CXX=/usr/bin/aarch64-linux-gnu-g++
FORCE=YES ./libretro-buildbot-recipe.sh recipes/linux/cores-linux-aarch64


### Building individual cores (or anything else)
There are two sets of environment variables set up in the image. The default is the toolchain installed from Ubuntu:
```
CC=/usr/bin/arm-linux-gnueabihf-gcc
AR=/usr/bin/arm-linux-gnueabihf-gcc-ar
CXX=/usr/bin/arm-linux-gnueabihf-g++
PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig/
```
The other one is the toolchain built by crosstools-ng, extended with libs of the default toolchain:
```
CXX17="/opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-g++ -idirafter /usr/include -L/usr/lib/arm-linux-gnueabihf/"
CC17="/opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc -idirafter /usr/include -L/usr/lib/arm-linux-gnueabihf/"
AR17=/opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc-ar
```
It is highly dependent on the build system, whether cross compilation will be possible, and if so, what platform / arch / target values need to be used. Libretro cores usually honor values of CC/CXX, so to use the newer compiler, try `CC=$(CC17) CXX=$(CXX17) make platform=unix-armv7`. But there is no guarantee that build system will recognize this target correctly, you need to read the makefile.

## More details
The reason why the build is based on such an old Ubuntu release is to avoid any library dependency problem when using the compiled images. The libretro base image can probably be substituted with a clean build from xenial as well, but it speeds up the build process.

The image has the Linaro gcc5 by default, and gcc9.4 compiled as extra. Default architecture for the compilers:
```
root@c17ce0b175c6:~# echo | $CC -v -E - 2>&1 | grep cc1
 /usr/lib/gcc-cross/arm-linux-gnueabihf/5/cc1 -E -quiet -v -imultiarch arm-linux-gnueabihf - -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3-d16 -mthumb -mtls-dialect=gnu -fstack-protector-strong -Wformat -Wformat-security
root@c17ce0b175c6:~# echo | $CC17 -v -E - 2>&1 | grep cc1
 /opt/x-tools/arm-linux-gnueabihf/libexec/gcc/arm-linux-gnueabihf/9.4.0/cc1 -E -quiet -v -idirafter /usr/include - -mcpu=arm10e -mfloat-abi=hard -mtls-dialect=gnu -marm -march=armv5te+fp
```
The gcc9 setup tries to mimic the environment used for gcc5, to avoid any compatibility problems. However, it contains less fixed elements, in particular architecture can go lower than the armv7-a default of gcc5. Usage of neon is not hardcoded anywhere, except for the target name in libretro-super (which, in turn, may cause the makefile to enable it).

## Caveats
- `gcc` is present, but it produces x86_64 code, if this happens, makefile has redefined CC/CXX. Use `readelf -h` on the produced binary to check.
- hardfloat is coming from compiler (both compilers)
- compiling for armv6 is theoretically supported but needs to be tested (see https://stackoverflow.com/questions/35132319/build-for-armv6-with-gnueabihf/51201725#51201725)
- `cmake` is present but wasn't tested in detail
- image does not contain any particular HW library like `libbrcmEGL` for Raspberry Pi. so it will not be able to link against that. This may mean a severe performance hit for any core that uses OpenGL (or Retroarch itself), depending on OS. See https://forums.raspberrypi.com/viewtopic.php?t=317511 for some RPi specifics.
- image is for Unix/Linux target. Does not contain any Android or iOS tools.
