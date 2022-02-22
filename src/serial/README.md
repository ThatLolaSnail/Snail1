# Serial communication for the `SNAIL I`

Ok, so the first tests I did with the `Snail I` used only the front panel for I/O. Then I added the SD card and LCD. But this time I wanted to try something different: Serial I/O

Serial connections are used for terminals, teletypes and tape punches/readers.
But all this old hardware is now very expensive, so I'll be using a modern computer and a USB to serial converter.

I removed the LCD and SD card slots for this, so the Serial connection is the only i/o we have.

## I/O-Map

| I/O Address | Descrition |   3    |   2    |   1    |   0    |
| ---         | ---        |  ---   |  ---   |  ---   |  ---   |
| 0x00  OUT   | SD card    |   -    |    -   |   -    |  Tx (1)|
| 0x10  IN    | SD card    |   -    |    -   |   -    |  Rx    |

(Default values in brackets)

Remember that Tx from the `Snail I` is connected to Rx (white) on the serial to USB converter and Rx is connected to Tx (green).

You might have realized that... 
I didn't use any real serial hardware... 
That's because I want to use bitbanging for that because that way I don't need any real hardware...
At this point you might have realized that the CPU and the RAM are the only pieces of real hardware that I'm using here.

## Interrupts

Ok, maybe a little bit of hardware: Interrupts.

the Rx line is also connected to the INT line. So whenever we receive the start bit (high to low transition), 
we can trigger this interrupt and handle the received data. Just make sure that the interrupt mode is set correctly and disable the interrup during the interrupt routine.

## The code

Ok, so I'll write 2 pieces of code: the serial Tx program to send an arbitrary amount of data over the serial connection, where we count machine cycles to aerchieve preceise timing,
and the serial Rx routine, which is called with the 'serial interrupt'.
This function disables the interrupt, receives the 8 bits and enables the interrut again, to be triggered with the next start bit.

Oh, by the way, I think I'll use 38400 baud. (9600*4)

:wq
