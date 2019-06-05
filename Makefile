
REVISION=$(shell git rev-list --count HEAD master)
SH3_FOLDER=C:\Games\Silent Hunter 3
LDFLAGS=-LC:\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\i686-w64-mingw32\lib -lmsvcrt -lkernel32 -luser32 -lwinhttp

patSH3r.act: patSH3r.o report.o string.o time.o misc.o
	ld -shared -o $@ --exclude-all-symbols -s $^ $(LDFLAGS)

%.o: %.asm
	nasm $(AFLAGS) -I src -f win32 -d PATSH3R_REV=$(REVISION) -o $@ $^

install:
	copy /y patSH3r.act "$(SH3_FOLDER)"

clean:
	del *.o patSH3r.act

