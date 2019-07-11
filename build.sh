#!/bin/bash

# Get start time
SECONDS==${SECONDS:=0}
START_TIME=${START_TIME:=$(date +"%Y%m%dT%H%M")}

# Set number of cores to compile with
COMPILE_CORES=$(echo "($(nproc) * 1.5)" | bc | awk '{print int ($1)}')

# Fetch Linux kernel source
git clone --depth 1 --branch $KERNEL_BRANCH $KERNEL_REPO ${WORKDIR}/${KERNEL_BRANCH}

# Change directory to kernel branch repo
cd ${WORKDIR}/${KERNEL_BRANCH}

# Compile configuration
make -j ${COMPILE_CORES} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcmrpi3_defconfig

# Compile kernel
make -j ${COMPILE_CORES} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

# Change directory to working directory
cd ${WORKDIR}

if [[ ! -f raspbian_lite_latest.zip ]]; then
    # Download latest Raspbian image from raspberrypi.org
    curl -L https://downloads.raspberrypi.org/raspbian_lite_latest -o raspbian_lite_latest.zip
fi

# Unzip raspbian image
unzip raspbian_lite_latest.zip

# Get Image Name
IMAGE_NAME=$(ls *.img)

# Get Image Version
IMAGE_VER=$(echo $IMAGE_NAME | cut -d"-" -f1,2,3)

# Get image sector size
SECTOR_SIZE=$(fdisk -l ${IMAGE_NAME}  | grep "Units" | awk '{print $6}')

# Get root partition starting sector
ROOT_PART_START=$(fdisk -l ${IMAGE_NAME} | grep "img2" | awk '{print $2}')
ROOT_PART_OFFSET=$(echo ${SECTOR_SIZE} '*' ${ROOT_PART_START} | bc)

# Get boot partition starting sector
BOOT_PART_START=$(fdisk -l ${IMAGE_NAME} | grep "img1" | awk '{print $2}')
BOOT_PART_SECTORS=$(fdisk -l ${IMAGE_NAME} | grep "img1" | awk '{print $4}')
BOOT_PART_OFFSET=$(echo ${SECTOR_SIZE} '*' ${BOOT_PART_START} | bc)
BOOT_PART_SIZELIMIT=$(echo ${SECTOR_SIZE} '*' ${BOOT_PART_SECTORS} | bc)

# Mount Root FS
mount -o loop,offset=${ROOT_PART_OFFSET} ${IMAGE_NAME} /mnt
mount -o loop,offset=${BOOT_PART_OFFSET},sizelimit=${BOOT_PART_SIZELIMIT} ${IMAGE_NAME} /mnt/boot

# Change directory to kernel branch repo
cd ${WORKDIR}/${KERNEL_BRANCH}

# Copy compiled kernel and device tree to boot partition 
cp arch/arm64/boot/Image /mnt/boot/kernel8.img
cp arch/arm64/boot/dts/broadcom/*.dtb /mnt/boot/

# Force boot into 64-bit kernel
#echo "kernel=kernel8.img" >> /mnt/boot/config.txt

# Install kernel modules
make -j ${COMPILE_CORES} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu INSTALL_MOD_PATH=/mnt modules_install

# Unmount filesystems
umount /mnt/boot
umount /mnt

# Change directory to working directory
cd ${WORKDIR}

# Rename image
NEW_IMAGE_NAME=$(echo ${IMAGE_NAME} | sed "s/\(.*\).img/\1-arm64-${KERNEL_BRANCH}-${START_TIME}.img/")
mv ${WORKDIR}/${IMAGE_NAME} ${WORKDIR}/${NEW_IMAGE_NAME}

# Zip image up
ZIP_NAME=$(echo ${NEW_IMAGE_NAME} | sed 's/\(.*\).img/\1.zip/')
zip ${ZIP_NAME} ${NEW_IMAGE_NAME}

# Copy new image to mounted volume
cp ${WORKDIR}/${ZIP_NAME} ${BUILDS}/

# Get start time
END_TIME=$(date +"%Y%m%dT%H%M")

# Display build time statistics
echo "Build Start Time: ${START_TIME}"
echo "Build End Time: ${END_TIME}"
echo "Build Duration: $(($SECONDS / 60)) minutes $((${SECONDS} % 60)) seconds"

# Exit gracefully
exit 0
