
REVISION=$(shell git rev-list --count HEAD master)
SH3_FOLDER=C:\Games\Silent Hunter 3
LDFLAGS=-LC:\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\i686-w64-mingw32\lib -lmsvcrt -lkernel32 -luser32
VPATH=src

patSH3r.act: patSH3r.o sh3.o patches.o
	ld -shared -o $@ -s $^ $(LDFLAGS)

%.o: %.asm
	nasm -I src -f win32 -d PATSH3R_REV=$(REVISION) -o $@ $^

install:
	copy /y patSH3r.act "$(SH3_FOLDER)"

clean:
	del *.o patSH3r.act

