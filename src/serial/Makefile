#NAME:=serial

SOURCES:=$(wildcard *.s)
OBJECTS:=$(SOURCES:.s=.o)
BINS:=$(SOURCES:.s=.bin)

AS:=z80-elf-as
LD:=z80-elf-ld
OBJDUMP:=z80-elf-objdump
HEXDUMP:=xxd -a

LD_FLAGS:= --no-undefined 

all: $(BINS) Makefile

clean: 
	rm -f $(OBJECTS) $(BINS)
	rm -f *~ .*~

%.bin: %.o linker.ld
	$(LD) --oformat binary $< -o $@ $(LD_FLAGS) -T linker.ld
	$(HEXDUMP) $@

%.o: %.s
	$(AS) $< -o $@
	$(OBJDUMP) -d $@


.PHONY: all clean
