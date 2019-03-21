; vim: ft=nasm fdm=marker fmr={{{,}}}
;
; This is free and unencumbered software released into the public domain.
; 
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
; 
; In jurisdictions that recognize copyright laws, the author or authors
; of this software dedicate any and all copyright interest in the
; software to the public domain. We make this dedication for the benefit
; of the public at large and to the detriment of our heirs and
; successors. We intend this dedication to be an overt act of
; relinquishment in perpetuity of all present and future rights to this
; software under copyright law.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
; OTHER DEALINGS IN THE SOFTWARE.
; 
; For more information, please refer to <http://unlicense.org/>
;

%define SENSOR_VISUAL	0x01
%define SENSOR_HYDRO	0x0c

; Crew-qualifications
%define CREWQ_WATCH	0x00
%define CREWQ_MACHI	0x05
%define CREWQ_TORPE	0x06
%define CREWQ_REPEA	0x08

; Array-indexes for officers
%define OFFCR_BRIDG	0x00
%define OFFCR_ENGIN	0x02
%define	OFFCR_NAVIG	0x03
%define OFFCR_WEAPO	0x04
%define OFFCR_DIESE	0x05
%define OFFCR_ELECT	0x06
%define OFFCR_BTORP	0x07
%define OFFCR_BQUAR	0x08
%define OFFCR_SQUAR	0x09
%define	OFFCR_STORP	0x0a
%define OFFCR_REPEA	0x0b

%define SH3_CREWARR	0x5F6238
%define SH3_MAINCFG	0x544698

struc crew 
	.name		resb	52 ;   -(uses only 50)
	.index		resd	 1 ;  0-integer
	.nrcomp		resd	 1 ;  4-integer
	.renown		resd	 1 ;  8-float
	.patrols	resd	 1 ;  c-integer
	.type		resd	 1 ; 10-integer
	.grad		resd	 1 ; 14-integer
	.notused_a	resd	 1 ; 18 ? dword
	.morale		resd	 1 ; 1c-float
	.fatigue	resd	 1 ; 20-float
	.healthsts	resd	 1 ; 24-integer
	.waswounded	resd	 1 ; 28-integer
	.experience	resd	 1 ; 2c-float
	.rank		resd	 1 ; 30-integer
	.nrqual		resd	 1 ; 34-integer
	.quals		resd	 3 ; 38-integer
	.specability	resd	 1 ; 44-integer
	.medals		resd	 9 ; 48-integer
	.hitpoints	resd	 1 ; 6c-float
	.notused_b	resd	 1 ; 70 ? dword
	.notused_c	resd	 1 ; 74 ? dword
	.notused_d	resd	 1 ; 78 ? dword
	.headidx	resd	 1 ; 7c-integer
	.headtgaidx	resd	 1 ; 80-integer
	.bodyidx	resd	 1 ; 84-integer
	.bodytgaidx	resd	 1 ; 88-integer
	.hashelmet	resd	 1 ; 8c-integer
	.helmetidx	resd	 1 ; 90-integer
	.helmettgaidx	resd	 1 ; 94-integer
	.voiceIdx	resd	 1 ; 98-integer
	.prom		resb	 1 ; 9c-byte
	.medal		resb	 9 ; 9d-byte
	.qual		resb	 9 ; a6-byte
	.notused_e	resb	 1 ;
endstruc

; --- _sh3_cfg_flt
;
; [ filemanager.dll/GetPrivateProfileFloat ]
;
; arguments:
;	void  *ini
;	char  *section
;	char  *value
;	float  default
;
; return:
;	float
;
%define _sh3_cfg_flt 0x51D0A8

; --- _sh3_cfg_int
;
; [ filemanager.dll/GetPrivateProfileInt ]
;
; arguments:
;	void *ini
;	char *section
;	char *value
;	int   default
;
; return:
;	int
;
%define _sh3_cfg_int 0x51D08C

; --- _sh3_cfg_secexist
;
; [ filemanager.dll/SectionExists ]
;
; arguments:
;	void *ini
;	char *section
;
; return:
;	true	if found
;	false	if not found
;
%define _sh3_cfg_secexist 0x51D174

; --- _sh3_cfg_str
;
; [ filemanager.dll/GetPrivateProfileStringA ]
;
; arguments:
;	void   *ini
;	char   *section
;	char   *value
;	char   *buf
;	size_t  bufsz
;
; return:
;	?
;
%define _sh3_cfg_str 0x51D098

;
; --- _sh3_cfg_strp
;
; [ filemanager.dll/GetPrivateProfileStringPtr ]
;
; arguments:
;	void  *ini
;	char  *section
;	char  *value
;	char **dst
;
; return:
;	char*
;
%define _sh3_cfg_strp 0x51D094

; --- _sh3_cfg_yn
;
; [ filemanager.dll/GetPrivateProfileYesNo ]
;
; arguments:
;	void *ini
;	char *section
;	char *value
;	bool default
;
; returns:
;	true	on "Yes"
;	false	on "No"
;
%define _sh3_cfg_yn 0x51D134

extern _sh3_mvcrew
