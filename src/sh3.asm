
%include "syms.asm"

extern _LoadLibraryA@4

section .bss ; ----------------------------------------------------------------

_fmgrofs	resd	1 ; offset to filemanager.dll


section .data ; ---------------------------------------------------------------

fmgrfn:		db	"filemanager.dll", 0

section .text ; ---------------------------------------------------------------

_init_sh3:

	push	fmgrfn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	mov	[_fmgrofs], eax

	mov	al, EOK
	ret

	.failure:
	mov	al, ESH3INIT
	ret
