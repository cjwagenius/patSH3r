
%include "syms.asm"

section .data ; ---------------------------------------------------------------

fmgrfn:		db	"filemanager.dll", 0
_fmgr_get_bool	dd	0x000047b0
_fmgr_get_int	dd	0x00004590
_fmgr_get_dbl	dd	0x00005610


section .text ; ---------------------------------------------------------------

_init_sh3:
	push	fmgrfn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	add	[_fmgr_get_bool], eax
	add	[_fmgr_get_int], eax
	add	[_fmgr_get_dbl], eax
	mov	al, EOK
	ret

	.failure:
	mov	al, 1
	ret
