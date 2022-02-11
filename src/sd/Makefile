 #2161  vi test.s
 #2162  z80-elf-as test.s
 #2164  z80-elf-ld --oformat binary -o test a.out --no-undefined -T linker.ld
 #2165  z80-elf-objdump -d a.out 
 #2166  xxd test

NAME:=sd_stuff

BIN:=$(NAME).bin
SOURCE:=$(NAME).s
OBJECT:=$(NAME).o

AS:=z80-elf-as
LD:=z80-elf-ld
OBJDUMP:=z80-elf-objdump
HEXDUMP:=xxd -a

LD_FLAGS:= --no-undefined 

all: $(BIN) Makefile

clean: 
	rm -f $(OBJECT) $(BIN)

$(BIN): $(OBJECT) linker.ld
	$(LD) --oformat binary $< -o $@ $(LD_FLAGS) -T linker.ld
	$(HEXDUMP) $@

$(OBJECT): $(SOURCE)
	$(AS) $< -o $@
	#$(OBJDUMP) -d $@


.PHONY: all clean
