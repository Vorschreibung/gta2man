SHELL := bash
.SHELLFLAGS := -eo pipefail -c
.ONESHELL:
.SILENT:

.PHONY: help
help:
	awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^# \{\{\{/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 7) } ' $(MAKEFILE_LIST)

# {{{ Build
INPUTS := \
	./compile.nim \
	./config.nim \
	./edit.nim \
	./facts.nim \
	./gui.nim \
	./main.nim \
	./mmpfile.nim \
	./parseini.nim \
	./quickstart.nim \
	./res/gta2man.res \
	./utils.nim \
	./validator_name.nim \
	./various.nim \

./res/gta2man.res: ./res/gta2man.rc ./res/gta2man.ico ./res/gta2man.manifest
	i686-w64-mingw32-windres -O coff ./res/gta2man.rc -o ./res/gta2man.res

build: PHONY ./gta2man.exe ## build
./gta2man.exe: $(INPUTS)
	args=(
		\--cpu:i386 
		\--threads:on
		\-d:mingw 
		
		\-d:release 
		\--stackTrace:on
		\--lineTrace:on
		\-d:strip 
		\--opt:size
	)
	set -x
	nim c "$${args[@]}" --out:"gta2man.exe" ./main.nim

clean: PHONY ## clean outputs
	rm -f \
		./main.exe \
		./gta2man.exe \
		./tests/tester.exe

./tests/tester.exe: $(INPUTS) ./tests/tester.nim
	nim c --cpu:i386 -d:mingw --stackTrace:on --lineTrace:on ./tests/tester.nim

test: PHONY ./tests/tester.exe ## test
	wine ./tests/tester.exe

# --- --- --- --- --- --- --- --- ---

compile: PHONY ./compile.exe ## compile
./compile.exe: ./compile.nim
	args=(
		\--cpu:i386 
		\--threads:on
		\-d:mingw 
		
		\-d:release 
		\-d:strip 
		\--opt:size
	)
	set -x
	nim c "$${args[@]}" --out:"compile.exe" ./compile.nim

PHONY:
.PHONY: PHONY
