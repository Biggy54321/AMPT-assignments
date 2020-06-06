nasm -f bin -o bi.bin bi.asm
dd status=noxfer conv=notrunc if=bi.bin of=bi.flp
qemu-system-x86_64 -fda bi.flp
