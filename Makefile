.PHONY: clean run

bin/minisettings:
	nim c --backend:cpp --out:bin/minisettings $(EXTRA_COMPILER_FLAGS) src/main.nim

run:
	nim r --backend:cpp --out:bin/minisettings $(EXTRA_COMPILER_FLAGS) src/main.nim

clean:
	rm imgui.ini bin/minisettings
