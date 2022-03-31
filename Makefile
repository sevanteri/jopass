
MODULES := .janet_modules
DEPS := $(addprefix $(MODULES)/,_secret.so _process.so json.so)
MANIFESTS := $(MODULES)/.manifests

.PHONY: all
all: build

$(MODULES):
	mkdir $(MODULES)

$(MANIFESTS): $(MODULES)
	jpm -l deps

.PHONY: build
build: $(MANIFESTS)
	jpm -l build


.PHONY: clean
clean:
	jpm clean
	rm -rf $(MODULES)
