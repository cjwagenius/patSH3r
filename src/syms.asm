
;  Crew array (located at 0x5F6238)                            
;
;  The crew array contains information about all the crew. The total length
; of the array is not yet known. The indexes in the array are also positions
; in the u-boat and it's compartments.
;
;  When moving the crew manually (in game), the information in the source-
; index gets copied to the destination-index. If it's NOT an officer, the
; memory at the source index gets cleared (in some sence), otherwise only
; crew_s.nrComp will be set to a negative value. So the only reliable way to
; check if the slot is free/empty, is to check if crew_s.nrComp < 0.
;
; Indexes:
; 		0 WO
;		1 [Nothing ?]
;		2 CE
;		3 NO
;		4 WP
;		30 Helms 1
;		31 Helms 2
;		32 Helms 3
;
; Compartments:
; 					      Officer  		Type
; 	    Compartment		Index	       Index 	 	 II
; 	   ----------------------------------------------------------
; 	    Bridge		 13	 	 0		 4
;   	    Deck Casing		 17		 -		 -
; 	    Flak		 20		 -		 1
; 	    Sonar		 28		 -		 1
; 	    Radio		 29		 -		 1
; 	    Diesel Engines	 33		 5		 6
; 	    Electric Engines	 43		 6		 6
; 	    Bow Torpedo		 53		 7		10
; 	    Bow Quarters	 67		 8		13
; 	    Stern Quarters	 83		 9		 6
; 	    Stern Torpedo	 99		10		 -
;	    Repair		107		11		 8
;
; Repair len: IXB1, VII = 10 : XXI = 12
;


%define BUFSZ		1024

%define EOK		0x00
%define ESH3INIT	0x01
%define EMEMW		0x10
%define EFAIL		0xFF

%define ASM_NOOP	0x90
%define ASM_CALL	0xe8
%define ASM_JMP		0xe9
%define	ASM_RET		0xc3

%define CREWQ_WATCH	0x00
%define CREWQ_MACHI	0x05
%define CREWQ_TORPE	0x06
%define CREWQ_REPEA	0x08

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

; --- Win32 -------------------------------------------------------------------
%define DLL_ATTACH	0x01

extern _sprintf
extern _snprintf

extern _GetCurrentProcess@0
extern _GetLastError@0
extern _LoadLibraryA@4
extern _MessageBoxA@16
extern _WriteProcessMemory@20

; --- patSH3r.asm -------------------------------------------------------------
; functions
;extern _patch_mem
; variables
;extern _hsie		; db, is this a hsie-patched exe?
;extern _proc		; current process
;extern _buf		; temporary buffer of size BUFSZ

; --- sh3.asm -----------------------------------------------------------------
; functions
;extern _sh3_init	; init function
;extern _sh3_mvcrew
;extern _fmgr_get_yn	; get yes/no from ini-file
;extern _fmgr_get_int	; get integer from ini-file
;extern _fmgr_get_dbl	; get double from ini-file
;extern _fmgr_get_str	; get string from ini-file

; variables
;extern _crewofs		; offset to crew-array pointer
;extern _fmgrofs		; offset to filemanager.dll
;extern _maincfg		; offset to main.cfg object

; --- patches.asm -------------------------------------------------------------
;extern _ptc_version_init
;extern _ptc_smartpo_init
;extern _ptc_alertwo_init

