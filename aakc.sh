#!/bin/bash
# Advanced Android Kernel Compiler v1.0 
# by Kodeaqua
KHOME=$(pwd);

function sett() {
	local CC; local DEVICE; local CCACHE; local ARCH; local SUBARCH;

	read -p "Set your device's arch: " ARCH;
	echo "arch: $ARCH" > $KHOME/.settings;

	read -p "and subarch: " SUBARCH;
	echo "sub: $SUBARCH" >> $KHOME/.settings;

	read -p "Set your CC bin path: " CC;
	echo "toolchain: $CC" >> $KHOME/.settings;

	read -p "Set device: " DEVICE;
	echo "device: $DEVICE" >> $KHOME/.settings;

	read -p "Use ccache [y/n]: " CCACHE;
	echo "ccache: $CCACHE" >> $KHOME/.settings;
}

function buildKernel() {
	local ARCH=$(cat $KHOME/.settings | grep arch: | cut -d ' ' -f 2);
	local SUBARCH=$(cat $KHOME/.settings | grep sub: | cut -d ' ' -f 2);
	local KBUILD_BUILD_USER=$USER;
	local KBUILD_BUILD_HOST=$(cat /etc/hostname);
	
	local CROSS_COMPILE="$(cat $KHOME/.settings | grep toolchain: | cut -d ' ' -f 2)-";
	if [[ $(echo $CROSS_COMPILE | grep clang) ]]; then
		local BIN="clang";
	else
		local BIN="gcc";
	fi

	local ANYKERNEL=$KHOME/AnyKernel3;
	if ! [[ -d $ANYKERNEL ]]; then
		echo "[x] Checking connection...";
		echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
		if [ $? -eq 0 ]; then
    		echo "[x] Clonning AnyKernel3...";
			git clone --quiet https://github.com/osm0sis/AnyKernel3.git $ANYKERNEL;
		else
    		echo "[x] AnyKernel3 not found and you're not connected to internet. Exiting...";
			exit;
		fi
	fi

	local PRODS=$KHOME/Products;
	if ! [[ -d $PRODS ]]; then
		echo "[x] Creating productions dir"
		mkdir $PRODS;
	fi
	
	if [[ -f $KHOME/.config ]]; then
		echo "[x] Cleaning old config and codes...";
		make clean && make mrproper;
	fi
	echo "[x] Generating config...";
	make $(cat $KHOME/.settings | grep device: | cut -d ' ' -f 2)_defconfig;
	
	echo "[x] Compiling...";
	if [[ $(cat $KHOME/.settings | grep ccache: | cut -d ' ' -f 2) == Y && $(cat $KHOME/.settings | grep ccache: | cut -d ' ' -f 2) == y ]]; then
		make CC="ccache $BIN" OUT=$ANYKERNEL -j$(nproc --all);
	else
		make OUT=$ANYKERNEL -j$(nproc --all);
	fi;

	if [[ -f $KHOME/$ARCH/boot/*Image* ]]; then
		echo "[x] Creating flashable package...";
		cd $ANYKERNEL && zip -r9 $PRODS/Kernel.zip * -x .git README.md *placeholder >> /dev/null 2>&1;
		echo "[x] All operations was successfull!";
	fi;
	if ! [[ -f $KHOME/$ARCH/boot/*Image* ]]; then
		echo "[x] Failed to compile kernel!";
	fi
}

cd $KHOME;
if ! [[ -f $KHOME/.settings ]]; then
	sett;
fi;
buildKernel;