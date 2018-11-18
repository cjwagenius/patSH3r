
@set LDFLAGS=-lkernel32 -LC:\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\i686-w64-mingw32\lib
nasm -o patSH3r.o -f win32 src\patSH3r.asm
ld -o patSH3r.act -shared -s patSH3r.o %LDFLAGS%

