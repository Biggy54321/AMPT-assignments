nasm -f bin -o mtm.bin mtm.asm
dd status=noxfer conv=notrunc if=mtm.bin of=mtm.flp
qemu-system-x86_64 -fda mtm.flp
