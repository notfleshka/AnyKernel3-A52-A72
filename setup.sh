#!/bin/bash

LOGFILE="setup_log.txt"
# Start logging
exec > >(tee -a "$LOGFILE") 2>&1

# Tasks
echo "===== notfleshka's tools Setup Script ====="
echo "This script will perform the following tasks:"
echo "1. Copy configs (ksu.config, apatch.config, cert.config) to vendor folder"
echo "2. Copy build script"
echo "3. Optionally apply Android 16 AOSP patch to kernel"
echo "4. Optionally add KernelSU and SUSFS to kernel"
echo

read -p "Do you want to proceed with these tasks? (y/n): " consent
if [[ ! "$consent" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo "Aborted."
    exit 1
fi

# Copy configs
VENDOR_DIR="arch/arm64/configs/vendor"
echo "Copying configs..."
wget -q -O "$VENDOR_DIR/apatch.config" https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/apatch.config
wget -q -O "$VENDOR_DIR/cert.config" https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/cert.config
wget -q -O "$VENDOR_DIR/ksu.config" https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/ksu.config

# Copy build script
echo "Copying build script..."
wget -q -O build.sh https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/build.sh
chmod +x build.sh

# Android 16 AOSP Patch
read -p "Do you want to apply the Android 16 patch? (y/n): " patch_choice
if [[ "$patch_choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo "Downloading and applying Android 16 patch..."
    wget -q -O a16-support.patch https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/a16-support.patch
    patch -p1 < a16-support.patch
    echo "Android 16 patch applied. If any conflicts appear, resolve them manually."
else
    echo "Skipping Android 16 patch."
fi

# KernelSU & SUSFS integration
read -p "Do you want to add KernelSU to the kernel? (y/n): " ksu_choice
if [[ "$ksu_choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo "Running KernelSU integration..."
    # Select KSU solution
    echo "Select KSU solution to use:"
    echo "1) KernelSU by rsuntk (recommended)"
    echo "2) KernelSU-Next"
    echo "3) SukiSU Ultra (susfs-main, not recommended)"
    echo "4) SukiSU Ultra (non-gki branch + susfs patching, not recommended)"
    read -p "Enter choice [1-4]: " KSU_CHOICE

    case "$KSU_CHOICE" in
        1)
            echo "Running KernelSU by rsuntk setup..."
            curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh" | bash -s susfs-legacy
            ;;
        2)
            echo "Running KernelSU-Next setup..."
            curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
            echo "Entering KernelSU-Next directory..."
            cd KernelSU-Next || { echo "KernelSU-Next directory not found! Exiting."; exit 1; }
            echo "Downloading SUSFS patch..."
            curl -o 0001-Kernel-Implement-SUSFS.patch https://github.com/KernelSU-Next/KernelSU-Next/commit/3125c35dcfdf4ccadf3fe58b5dbc584c6bb54233.patch
            echo "Applying SUSFS patch..."
            patch -p1 < 0001-Kernel-Implement-SUSFS.patch
            echo "Returning to parent directory..."
            cd ..
            ;;
        3)
            echo "Running SukiSU Ultra (susfs-main) setup..."
            curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-main
            ;;
        4)
            echo "Running SukiSU Ultra (non-gki branch) setup..."
            curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s nongki
            echo "Entering SukiSU-Ultra directory..."
            cd SukiSU-Ultra || { echo "SukiSU-Ultra directory not found! Exiting."; exit 1; }
            echo "Downloading SUSFS patch..."
            wget https://gitlab.com/simonpunk/susfs4ksu/-/raw/kernel-4.14/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch
            echo "Applying SUSFS patch..."
            patch -p1 < 10_enable_susfs_for_ksu.patch
            echo "Returning to parent directory..."
            cd ..
            ;;
        *)
            echo "Invalid choice. Skipping."
            ;;
    esac

    # Ask user whether kernel has KernelSU hooks or not
    read -p "Does your kernel already have KernelSU hooks? [y/N]: " HAS_HOOKS
    if [[ "$HAS_HOOKS" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
        echo "Okay, continuing."
    else
        echo "Attempting to download and add KernelSU hooks..."
        curl -fsSL -o ksu-hooks.patch "https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/ksu-hooks.patch" || { echo "Failed to download with curl."; }
        echo "Applying KernelSU hooks..."
        patch -p1 < ksu-hooks.patch
        echo "Patch applied. If any conflicts appear, resolve them manually."
    fi
    echo "KSU Solution ($KSU_CHOICE) installation finished."
else
    echo "Skipping KSU installation."
fi

# Ask user if they want to continue to kernel patching
read -p "Do you want to patch kernel with SUSFS? [y/N]: " CONTINUE_PATCH
if [[ "$CONTINUE_PATCH" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo "Cloning SUSFS repository..."
    git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.14

    echo "Copying SUSFS patches..."
    cp -v susfs4ksu/kernel_patches/fs/* fs
    cp -v susfs4ksu/kernel_patches/include/linux/* include/linux

    echo "Applying SUSFS integration patch..."
    cp -v susfs4ksu/kernel_patches/50_add_susfs_in_kernel-4.14.patch .
    patch -p1 < 50_add_susfs_in_kernel-4.14.patch
    echo "Patch applied. If any conflicts appear, resolve them manually."
else
    echo "Skipping SUSFS patching."
fi

echo "All tasks completed."
echo "If there are any conflicts or problems present, check $LOGFILE and make sure to resolve them manually."
echo "Modify build.sh to you needs. All main variables are at the top of the script."
echo "===== Finished at $(date) ====="
