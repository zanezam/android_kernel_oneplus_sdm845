# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# mcd-kernel changes by mcdachpappe @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=## mcd-kernel for OnePlus 6/T ## ZZupreme-Build by ZaneZam ###
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus6
device.name2=enchilada
device.name3=OnePlus6T
device.name4=fajita
supported.versions=11 - 12
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## Trim data partition
$bin/busybox fstrim -v /data;

## Select the correct image to flash
userflavor="$(file_getprop /system/build.prop "ro.build.user"):$(file_getprop /system/build.prop "ro.build.flavor")";
case "$userflavor" in
  jenkins:qssi-user)
    os="oos";
    os_string="OxygenOS";
    ;;
  *)
    os="custom";
    os_string="a custom ROM";
    ;;
esac;
ui_print " " "You are on $os_string!";
if [ -f $home/kernels/$os/Image.gz-dtb ]; then
  mv $home/kernels/$os/Image.gz-dtb $home/Image.gz-dtb;
else
  ui_print " " "There is no kernel for your OS in this zip! Aborting..."; exit 1;
fi;

## AnyKernel boot install
dump_boot;

# Reset cmdline
patch_cmdline "is_androidR" "";

android_version=$(file_getprop /system/build.prop ro.build.version.release);

# Patch cmdline, if on Android 12
if [ $android_version = 12 ]; then
  patch_cmdline "is_androidR" "is_androidR";
fi;

# Install the boot image
write_boot;

## end boot install
