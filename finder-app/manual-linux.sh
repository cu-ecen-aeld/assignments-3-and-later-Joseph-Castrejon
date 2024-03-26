#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
PATCH_COMMIT=e33a814e772cdc36436c8c188d8c42d019fda639

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone "${KERNEL_REPO}" --depth 1 --single-branch --branch "${KERNEL_VERSION}"
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
 
    git checkout ${KERNEL_VERSION} 
 
   # TODO: Add your kernel build steps here  

    # Clean all previously generated files and start from clean working state 
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper

    #Apply patch to scripts/dtc/dtc-lexer.l
    git restore './scripts/dtc/dtc-lexer.l'
    sed -i '41d' './scripts/dtc/dtc-lexer.l'

    # Build default configuration for ARM64
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE V=1 defconfig
	
    # Build target 'all'.
    # I have a 16-core computer.
    make --jobs=16 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    
    # Build kernel modules
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules

    # Build device tree.
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs 

fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
echo "Creating initrd based on Linux FHS..."
mkdir -p "$OUTDIR/rootfs"
pushd "$OUTDIR/rootfs"
mkdir -p bin boot dev etc home lib lib64 media mnt opt proc sys root sbin sys var run
mkdir -p "usr/bin" "usr/include" "usr/lib" "usr/libexec" "usr/lib64" "usr/local" "usr/sbin" "usr/share" 
mkdir -p "home/conf"
mkdir -p "var/cache" "var/lib" "var/lock" "var/log" "var/tmp"
popd

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    echo "Cleaning project: BusyBox v${BUSYBOX_VERSION}"
    make distclean
    echo "Using default BusyBox configuration"
    make defconfig 
else
    cd busybox
fi

# TODO: Make and install busybox
echo "Building BusyBox"
make -j16 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
echo "Installing to root filesystem."
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" install

echo "Library dependencies"
pushd "${OUTDIR}/rootfs"
ln -s "bin/sh" "init"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"


# TODO: Add library dependencies to rootfs
echo "Copying library dependencies to root filesystem."
lib_dir="/opt/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64"

cp -v "${lib_dir}/ld-2.33.so" "${OUTDIR}/rootfs/lib64/ld-2.33.so"
ln -s "../lib64/ld-2.33.so" "lib/ld-linux-aarch64.so.1"
cp -v "${lib_dir}/libm-2.33.so" "${OUTDIR}/rootfs/lib64/libm-2.33.so"
ln -s "libm-2.33.so" "lib64/libm.so.6"
cp -v "${lib_dir}/libc-2.33.so" "${OUTDIR}/rootfs/lib64/libc-2.33.so"
ln -s "libc-2.33.so" "lib64/libc.so.6"
cp -v "${lib_dir}/libresolv-2.33.so" "${OUTDIR}/rootfs/lib64/libresolv-2.33.so"
ln -s "libresolv-2.33.so" "lib64/libresolv.so.2"
popd

# TODO: Make device nodes
echo "Creating device nodes..."
pushd "${OUTDIR}/rootfs/dev"

# See documentation: 
sudo mknod -m 666 null c 1 3 
sudo mknod -m 620 console c 5 1 
popd 

# TODO: Clean and build the writer utility
printf "Building 'finder-app' located in: %s\n" "${FINDER_APP_DIR}"
pushd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE="${CROSS_COMPILE}" -j16 writer

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -v writer "${OUTDIR}/rootfs/home/writer"
cp -v finder.sh "${OUTDIR}/rootfs/home/finder.sh"
cp -v ../conf/username.txt "${OUTDIR}/rootfs/home/conf/username.txt"
cp -v ../conf/assignment.txt "${OUTDIR}/rootfs/home/conf/assignment.txt"
cp -v finder-test.sh "${OUTDIR}/rootfs/home/finder-test.sh"
cp -v autorun-qemu.sh "${OUTDIR}/rootfs/home"
popd

# TODO: Chown the root directory
printf "Changing ownership of 'root' directory:\n"
pushd "$OUTDIR"
sudo chown -R 0:0 "$OUTDIR/rootfs" 
popd 

# TODO: Create initramfs.cpio.gz
# See kernel documentation: https://www.kernel.org/doc/html/latest/admin-guide/initrd.html
printf "Creating initramfs: \n"
pushd "${OUTDIR}/rootfs"
find . | cpio --quiet -H newc -ov --owner root:root | gzip -9 -n > "${OUTDIR}/initramfs.cpio.gz"
popd


printf "SUCCESS: All boot files created!\n"
printf "\tKernel %s -> %s\n" "${KERNEL_VERSION}" "${OUTDIR}/vmlinux"
printf "\tinitramfs -> %s\n" "${OUTDIR}/initramfs.cpio.gz"

