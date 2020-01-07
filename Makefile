SUPPORTDIR ?= support
BUILDDIR ?= build
RESPEC_RELEASE ?= gh-pages
REPOS = https://github.com/w3c/respec|$(RESPEC_RELEASE)  https://github.com/w3c/link-checker https://github.com/htacg/tidy-html5
TIDYCONF ?= $(firstword $(wildcard tidy.config webrtc-respec-ci/tidy.config))
LINEWRAP ?= false
LINEWRAPLENGTH = $(shell cat $(TIDYCONF) | grep "^wrap:" | cut -f 2 -d ' ')

ifndef TIDY
TIDY = $(SUPPORTDIR)/tidy-html5/build/cmake/tidy
BUILD_TIDY = true
endif
RESPEC_INSTALL ?= $(SUPPORTDIR)/respec/node_modules

INPUT = $(shell head -1 W3CTRMANIFEST | cut -d '?' -f 1)
OUTPUT = $(BUILDDIR)/output.html

.PHONY: check
check:: tidycheck linkcheck
# not including html5valid because it is broken until we figure how to run this with oracle-java8

.PHONY: tidycheck
tidycheck: $(TIDY)
	$(TIDY) -quiet -config $(TIDYCONF) -errors $(INPUT)
# optionally check line wrapping
ifeq (true,$(LINEWRAP))
	$(TIDY) -quiet -config $(TIDYCONF) $(INPUT) | diff -q $(INPUT) - || \
	  (echo $(INPUT)" has lines not wrapped at "$(LINEWRAPLENGTH)" characters" && false)
endif

.PHONY: html5valid
html5valid: $(OUTPUT)
# check that resulting HTML is valid
	html5validator --root $(dir $<)

.PHONY: linkcheck
linkcheck: $(OUTPUT) $(SUPPORTDIR)/link-checker
# check internal links only (we exclude http links to avoid reporting SNAFUs)
	perl -T $(SUPPORTDIR)/link-checker/bin/checklink -S 0 -q -b -X "^http(s)?:" $<

.PHONY: tidy
tidy: $(TIDY)
	$(TIDY) -quiet -config $(TIDYCONF) -m $(INPUT)
	sed -i 's/[[:space:]]*$$//' $(INPUT)

## Build prerequisites

include $(SUPPORTDIR)/repos.mk

$(SUPPORTDIR) $(BUILDDIR):
	@mkdir -p $@

to_url = $(firstword $(subst |, ,$(1)))
branch_arg = $(if $(word 2,$(subst |, ,$(1))),-b $(word 2,$(subst |, ,$(1))),)
to_dir = $(SUPPORTDIR)/$(notdir $(call to_url,$(1)))
to_dot = $(SUPPORTDIR)/.$(notdir $(call to_url,$(1)))

$(SUPPORTDIR)/repos.mk: $(SUPPORTDIR)
	@printf ' $(foreach repo,$(REPOS),$(call to_dir,$(repo)): $(call to_dot,$(repo))\n$(call to_dot,$(repo)): $<\n\t@[ -d $(call to_dir,$(repo)) ] && git -C $(call to_dir,$(repo)) pull || git clone --depth 5 $(call branch_arg,$(repo)) $(call to_url,$(repo)) $(call to_dir,$(repo))\n\t@touch $$@\n\n)' > $@

ifdef BUILD_TIDY
$(TIDY): $(SUPPORTDIR)/tidy-html5
	@cd $(SUPPORTDIR)/tidy-html5/build/cmake && cmake -DCMAKE_BUILD_TYPE=Release ../..
	@$(MAKE) -C $(SUPPORTDIR)/tidy-html5/build/cmake
endif

$(RESPEC_INSTALL): $(SUPPORTDIR)/respec
	@cd $(SUPPORTDIR)/respec && npm install

.PHONY: update force_update
update:: force_update $(foreach repo,$(REPOS),$(call to_dir,$(repo))) $(TIDY) $(RESPEC_INSTALL)
force_update::
	@touch $(SUPPORTDIR)/repos.mk

## Build a processed copy of the spec

BUILD_INPUT = $(shell tail -n +2 W3CTRMANIFEST)
BUILD_FILES = $(addprefix $(BUILDDIR)/,$(BUILD_INPUT))
include $(SUPPORTDIR)/build.mk
$(SUPPORTDIR)/build.mk: W3CTRMANIFEST $(SUPPORTDIR)
	@printf ' $(foreach f,$(BUILD_INPUT),$(BUILDDIR)/$(f): $(f) $(BUILDDIR)\n\t@mkdir -p $$(dir $$@)\n\tcp -f $$< $$@\n\n)' > $@

$(OUTPUT): $(INPUT) $(RESPEC_INSTALL) $(BUILD_FILES) $(BUILDDIR)
	node $(SUPPORTDIR)/respec/tools/respec2html.js -e --timeout 30 --src file://`pwd`/$< --out $@
	ls -l $@

## Machine setup

.PHONY: travissetup
# packaged software are directly installed from .travis.yml
# (eg. nodejs, libwww-perl, libcss-dom-perl)
travissetup::
	pip install html5validator

.PHONY: setup
setup::
	sudo apt-get install libwww-perl libcss-dom-perl perl python2.7 python-pip cmake
	sudo pip install html5validator

clean::
	rm -rf $(CURDIR)/support $(CURDIR)/build
