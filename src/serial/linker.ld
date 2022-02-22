/*ENTRY(_main);*/

SECTIONS {
	/*start_address = 0xC0A0;/**/
	start_address = 0x0000;/**/
	.text start_address : AT(start_address) {
		*(.text)
	}
}
