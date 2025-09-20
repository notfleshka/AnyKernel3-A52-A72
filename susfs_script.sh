#!/bin/bash

LOGFILE="susfs_log.txt"

# Start logging
exec > >(tee -a "$LOGFILE") 2>&1

echo "===== SUSFS + KernelSU-Next Script made by ChatGPT :D and fixed by notfleshka @ telegram ====="
echo "===== Started at $(date) ====="

# 1. Run the KernelSU-Next setup script
echo "[1/8] Running KernelSU-Next setup..."
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

# 2. Enter the KernelSU-Next directory
echo "[2/8] Entering KernelSU-Next directory..."
cd KernelSU-Next || { echo "KernelSU-Next directory not found! Exiting."; exit 1; }

# 3. Download SUSFS patch
echo "[3/8] Downloading SUSFS patch..."
curl -o 0001-Kernel-Implement-SUSFS.patch https://github.com/KernelSU-Next/KernelSU-Next/commit/3125c35dcfdf4ccadf3fe58b5dbc584c6bb54233.patch

# 4. Apply SUSFS patch
echo "[4/8] Applying SUSFS patch..."
patch -p1 < 0001-Kernel-Implement-SUSFS.patch

# 5. Back to kernel source directory
echo "[5/8] Returning to parent directory..."
cd ..

# 6. Clone the SUSFS repo for kernel 4.14
echo "[6/8] Cloning SUSFS repository..."
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.14

# 7. Copy SUSFS patches to the kernel directory
echo "[7/8] Copying SUSFS patches..."
cp -v susfs4ksu/kernel_patches/fs/* fs
cp -v susfs4ksu/kernel_patches/include/linux/* include/linux

# 8. Apply the additional SUSFS patch
echo "[8/8] Applying additional SUSFS patch..."
cp -v susfs4ksu/kernel_patches/50_add_susfs_in_kernel-4.14.patch .
patch -p1 < 50_add_susfs_in_kernel-4.14.patch

echo "Most likely there are conflicts(dont worry, they are almost always present), check $LOGFILE and make sure to resolve them manually."
echo "===== Finished at $(date) ====="
