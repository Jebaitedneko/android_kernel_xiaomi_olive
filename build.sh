#!/bin/bash

TC_64=gcc-4.9-64
TC_32=gcc-4.9-32

[ ! -d $TC_32 ] \
&& mkdir -p $TC_64 \
| git clone --depth=1 --single-branch https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-18.1 $TC_64

[ ! -d $TC_32 ] \
&& mkdir -p $TC_32 \
| git clone --depth=1 --single-branch https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-18.1 $TC_32

[ -d out ] && rm -rf out | mkdir -p out || mkdir -p out

export CROSS_COMPILE="$(pwd)/${TC_64}/bin/aarch64-linux-android-"
export CROSS_COMPILE_ARM32="$(pwd)/${TC_32}/bin/arm-linux-androideabi-"
export DTC_EXT=dtc

make O=out ARCH=arm64 olivelite-perf_defconfig
make O=out ARCH=arm64 -j$((`nproc`+4))

unset CROSS_COMPILE CROSS_COMPILE_ARM32 DTC_EXT
