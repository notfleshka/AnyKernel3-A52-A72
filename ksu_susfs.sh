#!/bin/bash

LOGFILE="ksu_susfs.txt"

# Start logging
exec > >(tee -a "$LOGFILE") 2>&1

echo "===== KSU-Based Root Solutions + SuSFS Installation Script made by ChatGPT :D and fixed by notfleshka @ telegram ====="
echo "===== Started at $(date) ====="

# Ask if user wants to install KSU
read -p "Do you want to install a KSU solution? [y/N]: " INSTALL_KSU
if [[ "$INSTALL_KSU" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    # Select KSU solution
    echo "Select KSU solution to use:"
    echo "1) KernelSU by rsuntk (recommended)"
    echo "2) KernelSU-Next"
    echo "3) SukiSU Ultra (susfs-main, not recommended)"
    echo "4) SukiSU Ultra (non-gki branch + susfs patching, not recommended)"
    read -p "Enter choice [1-3]: " KSU_CHOICE

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
            echo "Running SukiSU Ultra(susfs-main) setup..."
            curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-main
            ;;
        4)
            echo "Running SukiSU Ultra(non-gki branch) setup..."
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
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    echo "KSU Solution($KSU_CHOICE) installation finished."
else
    echo "Skipping KSU installation."
fi

# Ask user if they want to continue to kernel patching
read -p "Do you want to patch kernel with SUSFS? [y/N]: " CONTINUE_PATCH
    if [[ ! "$CONTINUE_PATCH" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
        echo "Exiting."
        exit 0
    fi

# Ask user whether kernel has KernelSU hooks or not
read -p "Does your kernel already have KernelSU hooks? [y/N]: " HAS_HOOKS
if [[ "$HAS_HOOKS" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    echo "Okay, continuing."
else
    echo "Attempting to download and add KernelSU hooks..."
    # Try to download patch
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o ksu-hooks.patch "https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/ksu-hooks.patch" || { echo "Failed to download with curl."; }
    else
        echo "Failed. Exiting.";
        exit 1
    fi

    echo "Applying KernelSU hooks..."
    patch -p1 < ksu-hooks.patch

    # Ask user to confirm whether patch applied cleanly
    read -p "Did it patch without any conflicts? [y/N]: " PATCH_OK
    if [[ "$PATCH_OK" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
        echo "Patch applied successfully. Continuing..."
    else
        echo "Please resolve them manually, then re-run the script. Exiting."
        exit 1
    fi
fi

# Clone the SUSFS repo for kernel 4.14
echo "Cloning SUSFS repository..."
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.14

# Copy SUSFS patches to the kernel directory
echo "Copying SUSFS patches..."
cp -v susfs4ksu/kernel_patches/fs/* fs
cp -v susfs4ksu/kernel_patches/include/linux/* include/linux

# Apply the SUSFS integration patch
echo "Applying SUSFS integration patch..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o susfs.patch "https://raw.githubusercontent.com/notfleshka/AnyKernel3-A52-A72/refs/heads/master/susfs.patch" || { echo "Failed to curl."; }
else
    echo "Failed. Exiting.";
    exit 1
fi
patch -p1 < susfs.patch

echo "Most likely there are conflicts(dont worry, they are almost always present), check $LOGFILE and make sure to resolve them manually."
echo "===== Finished at $(date) ====="
