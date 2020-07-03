
MODULES = .janet_modules

$(MODULES):
	mkdir $(MODULES)

.PHONY: all
all: build

.PHONY: path
deps: $(MODULES)
	JANET_PATH=$(MODULES) jpm deps

.PHONY: build
build: $(MODULES) deps
	JANET_PATH=$(MODULES) jpm build


.PHONY: clean
clean:
	jpm clean
	rm -rf $(MODULES)
