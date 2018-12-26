; vim: ft=nasm fdm=marker fmr={{{,}}}

extern _MultiByteToWideChar@24

%define CP_UTF8		65001

global _w32_mbtowc
global _w32_wctomb

extern	_MultiByteToWideChar@24
extern	_WideCharToMultiByte@32


section .text

_w32_mbtowc: ; {{{

	; converts multibyte string to wide char string
	;
	; convert at most ecx chars. if ecx = 0, return required
	; buffer length in wide chars.
	;
	; arguments:
	;	esi	src
	;	edi	dst
	;	ecx	number of chars in buffer @ edi
	;
	; returns:
	;	ecx	characters written (or needed)
	;
	; --------------------------------------------------------------------

	push	eax

	push	ecx
	push	edi
	push	dword -1
	push	esi
	push	dword 1		; MB_PRECOMPOSED
	push	dword CP_UTF8
	call	_MultiByteToWideChar@24
	mov	ecx, eax

	pop	eax
	ret

; }}}
_w32_wctomb: ; {{{

	; converts wide char string to multibyte char string
	;
	; write at most ecx bytes. if ecx = 0, return required
	; buffer length.
	;
	; arguments:
	;	esi	src
	;	edi	dst
	;	ecx	number of bytes in buffer @ edi
	;
	; returns:
	;	ecx	bytes written (or needed)
	;
	; --------------------------------------------------------------------

	push	eax

	push	0		; no lpUsedDefaultChar when utf-8
	push	0		; no lpDefaultChar when utf-8
	push	ecx
	push	edi
	push	dword -1
	push	esi
	push	0		; noflags
	push	CP_UTF8
	call	_WideCharToMultiByte@32
	mov	ecx, eax

	pop	eax

; }}}

