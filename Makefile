.PHONY: clean run

COMPILER_ARGS := --backend:cpp $(EXTRA_COMPILER_ARGS)

bin/minisettings:
	nim c $(COMPILER_ARGS) --out:bin/minisettings src/main.nim

run:
	nim r $(COMPILER_ARGS) --out:bin/minisettings src/main.nim

clean:
	rm imgui.ini bin/minisettings
