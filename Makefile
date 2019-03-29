SOURCES=src/main.asm
GENERATED=main.exe
COMPILER=nasm
.PHONY: build run

build:
	$(COMPILER) $(SOURCES) -o $(GENERATED) && chmod +x $(GENERATED)

run: build
	./$(GENERATED)