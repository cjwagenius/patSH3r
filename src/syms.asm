
%define EOK		0x00
%define EFAIL		0xFF

; --- Win32 -------------------------------------------------------------------
extern _LoadLibraryA@4

; --- sh3.asm -----------------------------------------------------------------
extern _init_sh3

; Config value functions
;
; arg 1: ini-section
; arg 2: config-value
; arg 3: default value
;
extern _fmgr_get_bool
extern _fmgr_get_int
extern _fmgr_get_dbl

