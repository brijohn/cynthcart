
DASM?=dasm
PUCRUNCH?=pucrunch

all: standard kerberos emulation symphony mpu401 cartridge

standard:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcart.prg -DMODE=1 -DDEVICE_CONFIG=0

kerberos:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcart_kerberos.prg -DMODE=1 -DDEVICE_CONFIG=1

emulation:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcart_emu.prg -DMODE=1 -DDEVICE_CONFIG=2

symphony:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcart_symphony.prg -DMODE=1 -DDEVICE_CONFIG=3

mpu401:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcart_mpu401.prg -DMODE=1 -DDEVICE_CONFIG=4

cartridge:
	$(DASM) source/cynthcart.asm -Isource -f3 -v1 -obin/cynthcartUncompressed.bin -DMODE=2 -DDEVICE_CONFIG=0
	$(PUCRUNCH) bin/cynthcartUncompressed.bin bin/cynthcartRawCompressed.bin -c64 -l0x3000 -x0x3000 -d -m6 -ffast -fdelta
	$(DASM) source/cynthloader.asm -Ibin -f3 -v1 -obin/cynthcart_cartridge_ROM.bin -DMODE=0 -lbin/loaderSymbolList.txt

clean:
	rm -rf bin/*.prg bin/*.bin bin/*.txt
