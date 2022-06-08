.PHONY: clean run

bin/minisettings:
	nim c --backend:cpp --out:bin/minisettings $(EXTRA_COMPILER_FLAGS) src/main.nim

run: bin/minisettings
	./bin/minisettings

clean:
	rm imgui.ini bin/minisettings
