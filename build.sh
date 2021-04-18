#!/bin/bash

KROOT=$(pwd)
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

BUILD_START=$(date +"%s")

make O=out ARCH=arm64 olivelite-perf_defconfig
make O=out ARCH=arm64 -j$((`nproc`+4))

DIFF=$(($(date +"%s") - $BUILD_START))
echo -e "\nBuild completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

OSDIR=$KROOT/out/arch/arm64/boot
AKDIR=$OSDIR/anykernel3

(
	cd $OSDIR
	python3 $KROOT/scripts/mkdtboimg.py create dtbo.img dts/qcom/*.dtbo
)

[ ! -d $AKDIR ] && git clone --depth=1 --single-branch https://github.com/osm0sis/AnyKernel3 -b master $AKDIR

cat << EOF > $AKDIR/anykernel.sh
# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

properties() { '
kernel.string=generic
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=generic
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
'; }

block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;

. tools/ak3-core.sh;
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;

dump_boot;

ui_print "*******************************************"
ui_print "Updating Kernel and Patching cmdline to permissive..."
ui_print "*******************************************"

patch_cmdline androidboot.selinux androidboot.selinux=permissive

write_boot;
EOF

chmod +x $AKDIR/anykernel.sh

PREFIX=` cat $KROOT/out/.config | grep Linux | cut -f 3 -d " "  `
FORMAT=` date | sed "s/ /-/g;s/:/./g" `

(
	cd $AKDIR
	cp $OSDIR/Image.gz-dtb $AKDIR
	cp $OSDIR/dtbo.img $AKDIR
	zip -r ${PREFIX}_${FORMAT}.zip . -x '*.git*' '*modules*' '*patch*' '*ramdisk*' 'LICENSE' 'README.md'
	mv *.zip $KROOT/out
)

unset CROSS_COMPILE CROSS_COMPILE_ARM32 DTC_EXT OSDIR AKDIR KROOT PREFIX FORMAT TC_64 TC_32
