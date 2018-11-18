
%define DLL_ATTACH	0x01
%define FALSE		0x00
%define TRUE		0x01
%define EOK		0x00
%define EFAIL		0xFF

section .data
fmgrfn:		db	"filemanager.dll", 0
fmgr_get_bool	dd	0x000047b0
fmgr_get_int	dd	0x00004590
fmgr_get_dbl	dd	0x00005610

section .bss

; ------------------------------------------------------------------------------
section .text
extern _LoadLibraryA@4

global _DllMain

_DllMain:

	xor	eax, eax
	cmp	dword [esp+0x08], DLL_ATTACH ; exit if not attaching
	jne	.exit
	call	init

	.exit:
	and	eax, 0xFF
	cmp	al, EOK
	sete	al
	ret
	

init:

	push	fmgrfn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	add	[fmgr_get_bool], eax
	add	[fmgr_get_int], eax
	add	[fmgr_get_dbl], eax
	mov	al, EOK
	ret

	.failure:
	mov	al, 1
	ret


