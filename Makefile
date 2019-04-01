SOURCES=src/main.asm
GENERATED=main.com
COMPILER=nasm
DOSBOX=dosbox
.PHONY: build run

build:
	$(COMPILER) $(SOURCES) -o $(GENERATED) && chmod +x $(GENERATED)

run: build
	$(DOSBOX) -c "mount G ~/asm-game" -c "G:"