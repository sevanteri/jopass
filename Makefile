
MODULES := .janet_modules
DEPS := $(addprefix $(MODULES)/,_secret.so _process.so json.so)
MANIFESTS := $(MODULES)/.manifests

.PHONY: all
all: build

$(MODULES):
	mkdir $(MODULES)

$(MANIFESTS): $(MODULES)
	JANET_PATH=$(MODULES) jpm deps

.PHONY: build
build: $(MANIFESTS)
	JANET_PATH=$(MODULES) jpm build


.PHONY: clean
clean:
	jpm clean
	rm -rf $(MODULES)
