#!/bin/bash

dd if=/dev/zero of=disk.img bs=1M count=8
dd if=boot of=disk.img bs=512 count=1 conv=notrunc
dd if=head of=disk.img ibs=512 obs=512 count=4 seek=1 conv=notrunc
