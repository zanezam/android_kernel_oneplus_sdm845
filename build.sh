#!/bin/bash
######
#
#  Q&D build script for OnePlus 6/6T kernel by ZaneZam
#  based on infos from Nathan Chancellor (thx and credits!)
#  Details: https://github.com/nathanchance/android-kernel-clang
#
#  Infos about 'ZZupreme Builds' for which this script was mainly
#  made for: https://github.com/zanezam/ZZupreme-Builds
#
######

# save toolchain name option for later image file naming
TC="$1"

# keep the directory of execution
IAMHERE=`pwd`

# version of this script
SCRIPTVER="3.1"

# version of the build
BUILDVERSION=""

# keystore for signing zip
KEYSTORE="/path/to/keystore/zzupreme.keystore"

# project base dir
PROJECTDIR="/path/to/project-root"

# sources dir
SOURCEDIR="$PROJECTDIR/sources/android-linux-stable-op6"

# compile output dir (should be in git ignore list)
OUTDIR="out"

# anykernel template dir (included in this kernel repo)
ANYKERNEL="$SOURCEDIR/anykernel"

# force username for kernel string (if not set it will be the user which builds the kernel)
BUILDUSER=""
if [ -z "$BUILDUSER" ]; then
    BUILDUSER=$(whoami | sed 's/\\/\\\\/')
fi

# force hostname for kernel string (if not set it will be the hostname on which the kernel will be build on)
BUILDHOST=""
if [ -z "$BUILDHOST" ]; then
    BUILDHOST=`hostname`
fi

# mcdachpappe kernel release (source-base of the build)
cd $SOURCEDIR
BSREL=r`git tag --sort=committerdate | grep -E '[0-9]' | tail -1 | cut -b 2-7`

# name of the kernel (for zip package naming)
KERNAME="mcd-$BSREL-zzupreme"

# addendum to kernel version (for zip package naming)
VERSIONADD="op6x"

# default config to use for compilation (sdm845-perf_defconfig = default of unchanged sources)
KERNCONFIG="zzupreme_defconfig"

# name and location of build log file
BUILDLOG="$SOURCEDIR/$OUTDIR/zz_buildlog_$TC.log"

# release directory in which the ready kernel zips land
RELEASEDIR="$PROJECTDIR/releases"

# this is the linaro toolchain folder (root of toolchain folder without prefix)
LINAROTOOLCHAIN="/path/to/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu"

# this is a Linaro toolchain (binary prefix name)
LINGCCTOOLCHAIN="/path/to/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"

# this is the clang toolchain folder (root of toolchain folder without prefix of upstream toolchain version)
CLANGTOOLCHAIN="/path/to/toolchain/clang-r383902"

# this is the stock gcc toolchain folder for clang compilation (needed for linking etc. to fix odd issues)
STOCKTOOLCHAIN="/path/to/toolchain/aarch64-linux-android-4.9" # this is the folder to the android Q compatible gcc stock toolchain

# this is the stock 32bit gcc toolchain folder for clang compilation (needed for linking etc. to fix odd issues)
STOCK32TOOLCHAIN="/path/to/toolchain/arm-linux-androideabi-4.9"

# this is the stock 64bit gcc toolchain folder for clang compilation (provided toolchain: https://github.com/mcdachpappe/mcd-clang)
CROSSAARCHTOOLCHAIN="/path/to/toolchain/mcd-clang"

# set number of cpu cores to be used. leave empty for autodetection
NUM_CORES=

# get number of cpus for compile usage
if [ -z "$NUM_CORES" ]; then
    NUM_CORES=`nproc --all`
fi

# start time for compile timer
START=$(date +%s)

build="$1"

# compile time end
endtime()
{
    END=$(date +%s)
    ELAPSED=$((END - START))
    E_MIN=$((ELAPSED / 60))
    E_SEC=$((ELAPSED - E_MIN * 60))
    echo -e $COLOR_ORANGE
    printf "Image Build time: "
    echo -e $COLOR_NEUTRAL
    [ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
    printf "%d sec(s)\n" $E_SEC
}

pause()
{
    read -p "$1"
}

print_info()
{
    echo ""
    echo "Start $build building of $KERNAME-$BUILDVERSION-$VERSIONADD with kernel string: $BUILDUSER@$BUILDHOST / $KBUILD_COMPILER_STRING"
    echo ""
    sleep 1
}

sign_image()
{
    echo "Signing zip..."
    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE -tsa http://timestamp.digicert.com -storepass zzupreme $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.zip zzupreme 1> /dev/null 2>&1
    echo ""
    echo "Done!"
}

pack_image()
{
    # timestamp for filename
    STAMP=`date +%Y-%m-%d-%H%M%S`
    echo ""
    echo "Going to pack kernel image files into anykernel template zip now..."
    rm -f $OUTDIR/anykernel/kernel/placeholder
    rm -f $OUTDIR/anykernel/dtbs/placeholder
    cd  $OUTDIR/anykernel
    zip -r $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.zip .
    echo "Done!"
    echo ""
    sign_image
    md5sum $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.zip > $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.md5
    mv -f $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.zip $RELEASEDIR
    mv -f $KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.md5 $RELEASEDIR
    echo ""
    echo "$KERNAME-$BUILDVERSION-$VERSIONADD-$STAMP-$TC-anykernel.zip placed in $RELEASEDIR"
    echo ""
}

clean_tree()
{
    rm -rf $SOURCEDIR/$OUTDIR
}

build_clang() {
    export KBUILD_BUILD_VERSION=$BSREL
    export KBUILD_BUILD_USER=$BUILDUSER
    export KBUILD_BUILD_HOST=$BUILDHOST
    export KBUILD_COMPILER_STRING="$($CLANGTOOLCHAIN/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
    print_info
    clean_tree
    git checkout $1
    if [ -f arch/arm64/configs/$KERNCONFIG ]; then
        make O=$OUTDIR ARCH=arm64 $KERNCONFIG
    else
        echo "$KERNCONFIG config not found, be sure that it exist in $SOURCEDIR/arch/arm64/configs!!"
        exit 1
    fi
    ./scripts/config --file out/.config -e BUILD_ARM64_DT_OVERLAY
    make O=$OUTDIR ARCH=arm64 olddefconfig
    PATH="$CLANGTOOLCHAIN/bin:$CROSSAARCHTOOLCHAIN/bin:$STOCKTOOLCHAIN/bin:$STOCK32TOOLCHAIN/bin:${PATH}" make -j$NUM_CORES O=$OUTDIR ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=llvm- CROSS_COMPILE_AARCH=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- DTC_EXT=dtc 2>&1 | tee $BUILDLOG
    echo ""
    echo "Build done!"
    endtime && endtime >> $BUILDLOG
    if [ -f $SOURCEDIR/$OUTDIR/arch/arm64/boot/Image.gz ]; then
        cp -rf $ANYKERNEL $OUTDIR/anykernel
        if [ "$1" == "mcd-R-custom-zzupreme" ]; then
            flavor=custom
        elif [ "$1" == "mcd-R-custom-zzupreme" ]; then
            flavor=oos
        fi
        cp -f $SOURCEDIR/$OUTDIR/arch/arm64/boot/Image.gz $OUTDIR/anykernel/kernels/$flavor
        find . -name "*.dtb" -exec cp -f '{}' $OUTDIR/anykernel/kernels/$flavor \;
        cat $OUTDIR/anykernel/kernels/$flavor/Image.gz $OUTDIR/anykernel/kernels/$flavor/*.dtb > $OUTDIR/anykernel/kernels/$flavor/Image.gz-dtb;
        rm -f $OUTDIR/anykernel/kernels/$flavor/*.dtb
        rm -f $OUTDIR/anykernel/kernels/$flavor/Image.gz
    else
        echo "No image file found! Something went wrong, check $BUILDLOG!!"
        exit 1
    fi
}

case "$1" in

clang)
clear
build_clang mcd-R-custom-zzupreme
if [ "$2" == "break" ]; then
    pause "CUSTOM build done, press enter to continue with OOS build..."
fi
cp -f $SOURCEDIR/$OUTDIR/anykernel/kernels/custom/Image.gz-dtb $SOURCEDIR
$IAMHERE/$0 clean
build_clang mcd-R-zzupreme
if [ "$2" == "break" ]; then
    pause "OOS build done, press enter to continue with pack images into anykernel zip..."
fi
mv -f  $SOURCEDIR/Image.gz-dtb $SOURCEDIR/$OUTDIR/anykernel/kernels/custom/Image.gz-dtb
pack_image
$IAMHERE/$0 clean
;;

clean)
echo ""
cd $SOURCEDIR
echo "Sources cleaned, checking status of repo..."
echo ""
git status
;;

*)
echo ""
echo "Build Script $SCRIPTVER for ZZupreme Kernel Builds by ZaneZam"
echo ""
echo "Usage: $0 clang | clean"
echo "clang        - build with clang toolchain ($CLANGTOOLCHAIN)"
echo "clang break  - build with clang toolchain and stop between the build steps ($CLANGTOOLCHAIN)"
echo "clean        - clean sources (deletes dir $SOURCEDIR/$OUTDIR)"
echo ""
;;

esac
