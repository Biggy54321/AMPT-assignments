nasm -f bin -o rtp.bin rtp.asm
dd status=noxfer conv=notrunc if=rtp.bin of=rtp.flp
qemu-system-x86_64 -fda rtp.flp
