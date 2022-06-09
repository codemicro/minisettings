.PHONY: clean run

COMPILER_FLAGS := --backend:cpp $(EXTRA_COMPILER_FLAGS)

bin/minisettings:
	nim c $(COMPILER_FLAGS) --out:bin/minisettings $(EXTRA_COMPILER_FLAGS) src/main.nim

run:
	nim r $(COMPILER_FLAGS) --out:bin/minisettings $(EXTRA_COMPILER_FLAGS) src/main.nim

clean:
	rm imgui.ini bin/minisettings
