# SD card

Ok, writing programs by hand is fun, but what about storing files?
Historically, this is where tape came in. But the modern approach is, in my opinion, to use sd cards. 

## Hardware

Ok, first, how do we connect an sd card? A sd card has 9 pins. 
And it uses 3.3V. 
Let's make it simpler by using an arduino SD card module. 
These modules can be bought for cheap from your favorite online shop.
Just plug in a micro SD card on one side, and you have a 6 pin header on the other side.
This little board will do the voltage level stuff, so we just have to connect GND to GND and VCC to 5V.

There are 4 wires for the communication. DO, DI, SCLK and CS. DO is data out, I'll call it MISO (Master In Slave Out), and DI is data in, I'll call it MOSI (Master Out Slave In). SCLK is clock, which I sometimes call SCK, and CS is chip select, I call it EN (enable, active low). This is a usual SPI interface.
The communication is not the default like usual spi, first we have to initialize the card, so it knows that we want to use spi mode, and not the sd specific communication mode.
To do that, just do the initialisation before anything else.

I connected the SD card pins to the output port as described [here](https://github.com/ThatLolaSnail/Snail1#sd-card-slot).

## Software

So... How do we use the sd card?

Well, an sd card has commands that we need to send.
[Here](http://elm-chan.org/docs/mmc/mmc_e.html) is a very good explanation of all the sd stuff. But let me summarize it briefly:

- init the sd card:
  - Keep CS high and pulse the clock at least 80 times
  - try to send CMD0 until the result is not an error
  - try to send ACMD41 (which is CMD55 and CMD41 after one another), retry if nessecary
  - send CMD16 to select the sector size, most cards only support 512 bytes per sector.
- read one sector
  - I'm to lazy to implement that... See 'read multiple sectors'.
- read multiple sectors
  - send CMD18 with your address (multi block read)
  - receive a sector
  - discard 2 bytes, cause the card sends a checksum as well
  - repeat last 2 steps until you're done
  - send CMD12 to stop the read
  - send one FF byte just to wait 
  - after the response (every command has a response), wait until busy goes high (MISO is used as busy)
- write one sector
  - I'm to lazy to implement that... See 'write multiple sectors'.
- write multiple secotrs
  - send CMD25 with your address (multi block write)
  - wait a byte (0xFF) and send data_token (0xFC) before every block
  - send your sector
  - send a fake checksum (2 bytes), the card won't check it cause we use the old SPI mode
  - receive 4 bit data response and wait for the busy to go back high
  - repeat the last 4 steps until you're done
  - wait one byte (0xFF) and send the stop token (0xFD) and wait another byte (0xFF)
  - wait for busy to go back high (the MISO line)

Ok, so that's what I've written in sd_stuff.s!
Just toggle it in with the switches and you should be good to go.
To test this out, just write a short program that initializes the sd card and loads a sector from the card into RAM,
change some bytes by hand in the ram, 
and modify the program so it writes back instead, an re run it.
You can always use a computer with a hex editor to look what's on the card.

## File System??

No!

My idea is to use the card like a tape. Spool to an empty place on the tape, I mean, select an empty sector on the card, save to tape, i mean sd card, and remember the position where you saved it.
To load, just spool back the tape, I mean use the same address you used when saving, and just load the program again.

Modern computers use the first sector as the Master Boot Record. The first 446 (dec) bytes are executable code, then we have 4 partition entries with 16 bytes each, and then we have the value 0x55 and then the value 0xAA (0b01010101 0b10101010). If you plan on using the card with a computer, leave these 66 bytes intact, or just leave the first sector intact. just create an empty first partition, which you will use by hand, and create a 2nd partition that you can format for normal use. I would only use less than 4GB for our partition, cause we can only access the first 4GB of the card. So like 1 or 2 MB should be enough... Wait, is 4MB the smallest size that you can select? Doesn't matter. Just create a small first partition, and use the second partition for something else, if you want.

**Note**: The sd card wants the absolute address. To load the first sector (sector 0), give it the address 0x00000000, to load the second sector (sector 1), give it the address 0x00000200. Oh, yes, the sd card uses big endian, the Z80 uses little endian... I use registers BCDE for the address, in this order. B is highest, E is lowest. so use `LD BC, 0x0000`, `LD DE, 0x0200` (`110002`ENDIAN!!) to load the address. Don't forget to put the length in HL for my read and write command, for example 1 sector = 528 bytes: `LD HL, 0x0200` (`210002`)

## Demonstration of the sd card

```
SD_READ_TEST:
0000  00      NOP           ;becaus the memrq will be granted after this instruction
0001  310080  LD SP, 0x8000
0004  CD20C1  CALL 0xC120

