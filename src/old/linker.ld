/*ENTRY(_main);*/

SECTIONS {
	start_address = 0xC0A0;
	.text start_address : AT(start_address) {
		*(.text)
	}
}
