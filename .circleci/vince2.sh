#!/bin/bash
#
# Script For Building Android arm64 Kernel

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi
 
# MIUI = High Dimens
# OSS = Low Dimens

#export CHATID API_BOT TYPE_KERNEL

# Kernel build config
TYPE="VINCE"
KERNEL_NAME="SUPER.KERNEL"
KERNEL_NAME_ALIAS="Kernulvin-$(date +"%d-%m-%Y").zip"
DEVICE="Redmi 5 Plus"
DEFCONFIG="vince-perf_defconfig"
AnyKernel="https://github.com/missgoin/Anykernel3"
AnyKernelbranch="master"
HOSST="Pancali"
USEER="unknown"
ID="02"
MESIN="Git Workflows"

# clang config
REMOTE="https://gitlab.com"
TARGET="GhostMaster69-dev"
REPO="cosmic-clang"
BRANCH="master"

#REMOTE="https://gitlab.com"
#TARGET="Panchajanya1999"
#REPO="azure-clang"
#BRANCH="main"
#git clone --depth=1  https://gitlab.com/Panchajanya1999/azure-clang.git clang

# setup telegram env
export WAKTU=$(date +"%T")
export TGL=$(date +"%d-%m-%Y")

# clang stuff
echo -e "$green << cloning clang >> \n $white"
	git clone --depth=1 -b "$BRANCH" "$REMOTE"/"$TARGET"/"$REPO" "$HOME"/clang
	
        export PATH="$HOME/clang/bin:$PATH"
        export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')
        #export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Setup build process

build_kernel() {
Start=$(date +"%s")

	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee error.log

End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"
export KBUILD_BUILD_VERSION="$ID"

mkdir -p out

make O=out clean && make O=out mrproper
make ARCH=arm64 O=out "$DEFCONFIG" LLVM=1 LLVM_IAS=1

echo -e "$yellow << compiling the kernel >> \n $white"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
KOMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb
#export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
#export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

        if [ -f "$IMG" ]; then
                echo -e "$green << selesai dalam $(($Diff / 60)) menit and $(($Diff % 60)) detik >> \n $white"
        else
                echo -e "$red << Gagal dalam membangun kernel!!! , cek kembali kode anda >>$white"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cd zip
                export ZIP="$KERNEL_NAME_ALIAS"
		zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
		echo "Zip: $ZIP"
                curl -T $ZIP https://oshi.at; echo
		
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
				
                exit
        fi