; vim: ft=nasm fdm=marker fmr={{{,}}}

%include "string.inc"
%include "time.inc"

struc report
	.name		resb	48
	.rank		resd	 1
	.type		resb	 8 
	.uboat		resb	 8
	.heading	resd	 1
	.speed		resd	 1
	.long		resd	 1
	.lat		resd	 1
	.time		resd	 1
endstruc

extern		_sh3_maincfg
extern		_sh3_cfg_int
extern		_sh3_cfg_str

extern	_WinHttpCloseHandle@4
extern	_WinHttpConnect@16
extern	_WinHttpOpen@20
extern	_WinHttpOpenRequest@28
extern	_WinHttpQueryHeaders@24
extern	_WinHttpSendRequest@28
extern	_WinHttpSetStatusCallback@16

global _report_send

section .bss
handles:		resd	3
post_buf:		istruc report iend

section .data

threesixty:		dd	360.0
m_radius:		dq	6875493.0	; SH3 earth median radius
report_plrcfg		dd	0x005fed58	; handle to playersettings.cfg
report_strPLAYER	db	"PLAYER", 0
report_strName		db	"Name", 0
report_strRank		db	"Rank", 0
report_strPLAYER_SUB	db	"PLAYER_SUBMARINE", 0
report_strClassName	db	"ClassName", 0
report_strUnitName	db	"UnitName", 0
str_agent:		dw	__utf16__("patSH3r"), 0
str_server:		dw	__utf16__("fb.tuxxor.net"), 0
str_cgi:		dw	__utf16__("/cgi-bin/pbdu"), 0
str_post:		dw	__utf16__("POST"), 0

section .text
_report_send: ; {{{

	push	ebp
	mov	ebp, esp

	call	setup_post_data

	push	dword 0x10000000	; WINHTTP_FLAG_ASYNC
	push	dword 0			; WINHTTP_NO_PROXY_BYPASS
	push	dword 0			; WINHTTP_NO_PROXY_NAME
	push	dword 0			; WINHTTP_ACCESS_TYPE_DEFAULT_PROXY
	push	str_agent
	call	_WinHttpOpen@20
	test	eax, eax
	jz	.exit			; TODO: handle error
	mov	dword [handles+0], eax

	push	dword 0			; reserved
	push	80			; http
	push	str_server
	push	eax
	call	_WinHttpConnect@16
	test	eax, eax
	jz	.exit			; TODO: handle error
	mov	dword [handles+4], eax

	push	dword 0			; 
	push	dword 0			; WINHTTP_DEFAULT_ACCEPT_TYPES
	push	dword 0			; WINHTTP_NO_REFERER
	push	dword 0			; use HTTP/1.1
	push	str_cgi
	push	str_post
	push	eax
	call	_WinHttpOpenRequest@28
	test	eax, eax
	jz	.exit			; TODO: handle error
	mov	dword [handles+8], eax

	push	eax
	push	dword 0			; reserved
	push	dword 0x00020000	; HEADERS_AVAILABLE
	push	http_async_callback
	push	eax
	call	_WinHttpSetStatusCallback@16
	cmp	eax, dword -1
	je	.exit			; TODO: handle error
	pop	eax

	push	handles
	push	dword 88		; total length
	push	dword 88		; optional length
	push	post_buf
	push	dword 0			; header length
	push	dword 0			; WINHTTP_NO_ADDITIONAL_HEADERS
	push	eax
	call	_WinHttpSendRequest@28
	; TODO: handle result

	.exit:
	mov	esp, ebp
	pop	ebp

	ret

; }}}
meters_to_degrees: ; {{{

	; convert meters to degrees around earth
	;
	; arguments:
	;	st0	meters
	;
	; returns:
	;	st0	degrees
	;
	; ---------------------------------------------------------------------

	fld	qword [m_radius]
	fldpi
	fldpi
	faddp
	fmulp
	fdivp
	fld	dword [threesixty]
	fmulp

	ret

; }}}
coord_to_longlat: ; {{{

	; converts coordinates in meters to longitude and latitude
	;
	; arguments:
	;	st1	meters from equator
	;	st0	meters from Greenwich
	;
	; returns:
	;	st1	latitude
	;	st0	longitude
	;
	; ---------------------------------------------------------------------

	sub	esp, 8			;
	fstp	qword [esp]		; store away longitude

	call	meters_to_degrees	; convert latitude

	fld	qword [esp]		; restore longitude
	add	esp, 8
	call	meters_to_degrees	; convert longitude

	ret

; }}}
http_async_callback: ; {{{

	push	ebp
	mov	ebp, esp
	sub	esp, 12

	cmp	dword [ebp+16], 0x00020000	; HEADERS_AVAILABLE
	jne	.exit

	push	dword 0			; WINHTTP_NO_HEADER_INDEX
	mov	dword [ebp-4], 8
	lea	eax, [ebp-4]
	push	eax			; (int*) buffer sz
	push	dword esp		; buffer
	push	dword 0			; WINHTTP_HEADER_NAME_BY_INDEX
	push	dword 19		; WINHTTP_QUERY_STATUS_CODE
	mov	eax, [ebp+12]
	add	eax, 8
	push	dword [eax]
	call	_WinHttpQueryHeaders@24
	; TODO: handle response

	.cleanup:
	push	dword [handles+0]
	call	_WinHttpCloseHandle@4
	push	dword [handles+4]
	call	_WinHttpCloseHandle@4
	push	dword [handles+8]
	call	_WinHttpCloseHandle@4

	.exit:
	mov	esp, ebp
	pop	ebp
	ret

; }}}
sub_type_string: ; {{{

	push	ecx
	push	edx
	push	dword 0x005fd364	; push offset to sub-type array as
					; local variable

	push	0
	push	dword 0x00520a14	; "SubmarineType"
	push	dword 0x00520a0c	; "PLAYER"
	mov	ecx, [_sh3_maincfg]
	call	[_sh3_cfg_int]
	mov	edx, 224
	mul	edx
	add	dword [esp], eax	; add type offset

	push	0
	push	dword 0x005209f8	; "SubmarineVersion"
	push	dword 0x00520a0c	; "PLAYER"
	mov	ecx, [_sh3_maincfg]
	call	[_sh3_cfg_int]
	mov	edx, 20
	mul	edx
	add	eax, dword [esp]	; add version offset

	add	esp, 4
	pop	edx
	pop	ecx
	
	ret

; }}}
setup_post_data: ; {{{

	push	ecx
	push	esi
	push	edi

	; --- set career name -------------------------------------------------
	push	50
	lea	ecx, [post_buf + report.name]
	push	ecx
	push	0
	push	report_strName
	push	report_strPLAYER
	mov	ecx, [_sh3_maincfg]
	call	[_sh3_cfg_str]

	; --- set rank --------------------------------------------------------
	push	0
	push	report_strRank
	push	report_strPLAYER
	mov	ecx, [_sh3_maincfg]
	call	[_sh3_cfg_int]
	mov	[post_buf + report.rank], eax

	; --- set submarine type ----------------------------------------------
	call	sub_type_string
	lea	edi, [post_buf + report.type]
	mov	esi, eax
	xor	ecx, ecx
	call	_string_cpy

	; --- set submarine number --------------------------------------------
	push	8
	lea	ecx, [post_buf + report.uboat]
	push	ecx
	push	0
	push	report_strUnitName
	push	report_strPLAYER_SUB
	mov	ecx, [report_plrcfg]
	call	[_sh3_cfg_str]

	; --- set heading and speed -------------------------------------------
	mov	eax, [0x00554698]
	mov	ecx, [eax+84]
	mov	[post_buf + report.heading], ecx
	mov	ecx, [eax+88]
	mov	[post_buf + report.speed], ecx

	; --- set position ----------------------------------------------------
	mov	eax, [eax+244]
	fld	qword [eax+16]
	fld	qword [eax+ 8]
	call	coord_to_longlat
	fstp	dword [post_buf + report.long]
	fstp	dword [post_buf + report.lat]

	; --- set seconds since start -----------------------------------------
	call	_gametime_current
	call	_gametime_to_secs
	mov	dword [post_buf + report.time], eax

	mov	eax, post_buf
	pop	edi
	pop	esi
	pop	ecx

	ret
; }}}

