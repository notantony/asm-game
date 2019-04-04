SOURCES=src/main.asm
GENERATED=main.com
#COMPILER=nasm
COMPILER="C:\Program Files\NASM\nasm.exe"
#DOSBOX=dosbox
DOSBOX="C:\Program Files (x86)\DOSBox-0.74-2\DOSBox.exe"
PATH=~/asm-game
PATH=C:\Users\Anton\Desktop\asm-game
.PHONY: build run

build:
	$(COMPILER) $(SOURCES) -o $(GENERATED)

run: build
	$(DOSBOX) -c "mount G $(PATH)" -c "G:"