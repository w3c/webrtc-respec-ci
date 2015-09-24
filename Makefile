RESPEC_BRANCH=gh-pages
SUPPORTDIR=support
REPOS="https://github.com/w3c/respec https://github.com/dontcallmedom/webidl-checker https://github.com/dontcallmedom/widlproc https://github.com/dontcallmedom/linkchecker"
.PHONY: support
support:
	@mkdir -p $(SUPPORTDIR)
	@for repo in "$(REPOS)"; do \
		git clone $$repo $(SUPPORTDIR)/`basename $$repo`;\
	done
	@cd $(SUPPORTDIR)/respec && git checkout $(RESPEC_BRANCH) && cd ..
	@cd $(SUPPORTDIR)/widlproc && make obj/widlproc && cd ..

.PHONY: travissetup
travissetup: support
	# .travis.yml need to install libwww-perl libcss-dom-perl python-lxml
	@pip install html5lib html5validator

.PHONY: setup
setup: support
	sudo apt-get install libwww-perl libcss-dom-perl  python-lxml
	@pip install html5lib html5validator

.PHONY: update
update:
	@cd $(SUPPORTDIR)/respec && git checkout $(RESPEC_BRANCH) && cd ..
	for repo in "$(REPOS)"; do \
		echo $$repo && cd $(SUPPORTDIR)/`basename $$repo` && git pull ; cd .. ;\
	done

.PHONY: build
build:
	@mkdir -p build
	cat W3CTRMANIFEST|tail -n +2|xargs -I '{}' cp --parent '{}' build

.PHONY: check
check: build
	phantomjs --ignore-ssl-errors=true --ssl-protocol=tlsv1 $(SUPPORTDIR)/respec/tools/respec2html.js -e -w `cat W3CTRMANIFEST|head -1|cut -d '?' -f 1` build/output.html
	WIDLPROC_PATH=$(SUPPORTDIR)/widlproc/obj/widlproc python $(SUPPORTDIR)/webidl-checker/webidl-check build/output.html > /dev/null
	perl -T $(SUPPORTDIR)/linkchecker/bin/checklink -S 0  -q -b --suppress-broken 500 build/output.html
	html5validator --root build/
