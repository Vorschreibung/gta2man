SHELL := bash
.SHELLFLAGS := -eo pipefail -c
.ONESHELL:
.SILENT:

.PHONY: help
help:
	awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^# \{\{\{/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 7) } ' $(MAKEFILE_LIST)

# {{{ Build
INPUTS := \
	./config.nim \
	./main.nim \
	./mmpfile.nim \
	./parseini.nim \
	./sync_maps.nim \
	./utils.nim \
	./validator_name.nim \

./gta2man.exe: $(INPUTS)
	args=(
		\--cpu:i386 
		\-d:mingw 
		
		\-d:release 
		\-d:strip 
		\--opt:size
	)
	set -x
	nim c "$${args[@]}" --out:"gta2man.exe" ./main.nim

.PHONY: build
build: ./gta2man.exe ## build

./tests/tester.exe: $(INPUTS) ./tests/tester.nim
	nim c --cpu:i386 -d:mingw ./tests/tester.nim

.PHONY: test
test: ./tests/tester.exe ## test
	wine ./tests/tester.exe

.PHONY: clean
clean: ## clean outputs
	rm -f \
		./main.exe \
		./gta2man.exe \
		./tests/tester.exe
