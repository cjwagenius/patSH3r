; vim: ft=nasm fdm=marker fmr={{{,}}}

%include "misc.inc"

global _buf

section .bss ; ----------------------------------------------------------------
_buf:			resb	BUFSZ	; general working buffer

