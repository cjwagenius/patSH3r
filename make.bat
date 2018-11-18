
@set LDFLAGS=-lkernel32 -LC:\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\i686-w64-mingw32\lib
nasm -I src -o patSH3r.o -f win32 src\patSH3r.asm
nasm -I src -o sh3.o -f win32 src\sh3.asm
ld -o patSH3r.act -shared -s *.o %LDFLAGS%

