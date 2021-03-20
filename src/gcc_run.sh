#!/bin/bash

for dir_name in test*; do
	cd ${dir_name}
	echo "///////////////////////////////////////////////////////////////////"
	echo "///        enter ${dir_name}"
	echo "///////////////////////////////////////////////////////////////////"
	for file_name in test*.asm; do
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo "zma ${file_name} ${file_name}.bin"
		../code_coverage/zma ${file_name} ${file_name}.bin
		mv zma.log ${file_name}.log
	done
	cd ..
done
