
%include "syms.asm"

%define DLL_ATTACH	0x01

section .text ; ---------------------------------------------------------------

global _DllMain

_DllMain:

	xor	eax, eax
	cmp	dword [esp+0x08], DLL_ATTACH ; exit if not attaching
	jne	.exit
	call	init

	.exit:
	and	eax, EFAIL
	cmp	al, EOK
	sete	al
	ret
	

init:

	call	_init_sh3
	cmp	al, EOK
	jne	.exit

	.exit:
	ret

