RESPEC_BRANCH=gh-pages
SUPPORTDIR ?= $(CURDIR)/support
REPOS="https://github.com/w3c/respec https://github.com/dontcallmedom/webidl-checker https://github.com/dontcallmedom/widlproc https://github.com/dontcallmedom/linkchecker https://github.com/htacg/tidy-html5"
LINEWRAP=false
LINEWRAPLENGTH=100

INPUT=`cat W3CTRMANIFEST|head -1|cut -d '?' -f 1`

.PHONY: support
support:
	@mkdir -p $(SUPPORTDIR)
	@for repo in "$(REPOS)"; do \
		git clone $$repo $(SUPPORTDIR)/`basename $$repo`;\
	done
	@cd $(SUPPORTDIR)/respec && git checkout $(RESPEC_BRANCH) && cd ..
	@cd $(SUPPORTDIR)/tidy-html5/build/cmake && cmake ../.. && make
	@cd $(SUPPORTDIR)/widlproc && make obj/widlproc && cd ..

.PHONY: travissetup
# .travis.yml need to install libwww-perl libcss-dom-perl python-lxml
travissetup: support
	@pip install html5lib html5validator


.PHONY: setup
setup: support
	sudo apt-get install libwww-perl libcss-dom-perl perl phantomjs python2.7 python-pip python-lxml cmake
	sudo pip install html5lib html5validator

.PHONY: update
update:
	for repo in "$(REPOS)"; do \
		echo $$repo && cd $(SUPPORTDIR)/`basename $$repo` && git pull ; cd .. ;\
	done
	@cd $(SUPPORTDIR)/respec && git checkout $(RESPEC_BRANCH) && cd ..
	@cd $(SUPPORTDIR)/widlproc && make obj/widlproc && cd ..

.PHONY: build
build:
	@mkdir -p build
# copy auxiliary files listed in W3CTRMANIFEST
	cat W3CTRMANIFEST|tail -n +2|xargs -I '{}' cp --parent '{}' build

.PHONY: check
check: build
# check input to respec is clean
	$(SUPPORTDIR)/tidy-html5/build/cmake/tidy -quiet -errors $(INPUT)
# optionally check line wrapping
	if [ "$(LINEWRAP)" = "true" ] ; then \
	$(SUPPORTDIR)/tidy-html5/build/cmake/tidy -quiet --tidy-mark no -i -w $(LINEWRAPLENGTH) -utf8 $(INPUT)|diff -q $(INPUT) - || echo $(INPUT)" has lines not wrapped at "$(LINEWRAPLENGTH)" characters" && false;\
	fi
# check respec validity
	phantomjs --ignore-ssl-errors=true --ssl-protocol=tlsv1 $(SUPPORTDIR)/respec/tools/respec2html.js -e -w $(INPUT) build/output.html
# check WebIDL validity
	WIDLPROC_PATH=$(SUPPORTDIR)/widlproc/obj/widlproc python $(SUPPORTDIR)/webidl-checker/webidl-check build/output.html > /dev/null
# check that resulting HTML is valid
	html5validator --root build/
# check internal links (we exclude http links to avoid reporting SNAFUs)
	perl -T $(SUPPORTDIR)/linkchecker/bin/checklink -S 0  -q -b -X "^http(s)?:" build/output.html

.PHONY: linewrap
linewrap:
	$(SUPPORTDIR)/tidy-html5/build/cmake/tidy -quiet --tidy-mark no -i -w $(LINEWRAPLENGTH) -utf8 -m $(INPUT)

