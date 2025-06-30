# kunx - Kernighan using unix
# 30 Jun 2025
# 'makewords' command - word per line

.section .rodata
	.usage_msg: .string "makewords-command: makewords <filename>\n"
	.usage_len: .quad   40

	.unable_msg: .string "makewords-command: unable to open/read file\n"
	.unable_len: .quad   39

