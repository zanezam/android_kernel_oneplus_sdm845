# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=## mcd-kernel for OnePlus 6/T by mcdachpappe ## ZZupreme-Build by ZaneZam ###
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus6
device.name2=enchilada
device.name3=OnePlus6T
device.name4=fajita
device.name5=
supported.versions=10 - 13
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 750 750 $ramdisk/*;

## Trim data partition
$BB fstrim -v /data;

## Select the correct image to flash / Detect first appearance in build.prop only
USERFLAVOR="$(grep -m 1 "^ro.build.user" /system/build.prop | cut -d= -f2):$(grep -m 1 "^ro.build.flavor" /system/build.prop | cut -d= -f2)";

case "$USERFLAVOR" in
  "OnePlus:OnePlus6-user" | "OnePlus:OnePlus6T-user" | "jenkins:qssi-user")
    OS="oos";
    OS_STRING="OxygenOS";
    ;;
  *)
    OS="custom";
    OS_STRING="a custom ROM";
    ;;
esac;

ui_print " " "You are on $OS_STRING!";

# Move kernel image
if [ -f $home/kernels/$OS/Image.gz-dtb ]; then
  mv $home/kernels/$OS/Image.gz-dtb $home/Image.gz-dtb;
else
  ui_print " " "There is no kernel for your OS in this zip! Aborting..."; exit 1;
fi;

## AnyKernel boot install
dump_boot;

# Reset cmdline
patch_cmdline "pre_android_S" "";

# Get Android version
android_version=$(file_getprop /system/build.prop "ro.build.version.release");

# Patch cmdline, if on custom ROM Android 11 (R) and below
if [ "$OS" = "custom" ] && [ "$android_version" \< "12" ]; then
  patch_cmdline "pre_android_S" "pre_android_S";
fi;

write_boot;
## end boot install
