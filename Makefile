RESPEC_BRANCH=master
SUPPORTDIR=support

.PHONY: support
support:
	DIR=`pwd`
	@mkdir -p $(SUPPORTDIR) 
	@git clone https://github.com/w3c/respec.git -b $(RESPEC_BRANCH) $(SUPPORTDIR)/respec
	@git clone https://github.com/dontcallmedom/webidl-checker.git $(SUPPORTDIR)/webidl-checker
	@git clone https://github.com/dontcallmedom/widlproc $(SUPPORTDIR)/widlproc
	@git clone https://github.com/halindrome/linkchecker.git $(SUPPORTDIR)/linkchecker
	@cd $(SUPPORTDIR)/widlproc && make obj/widlproc && cd ..

.PHONY: install
install: support
	@apt-get install libwww-perl cpanminus
	@cpanm install CSS::DOM
	@pip install html5lib lxml html5validator

.PHONY: build
build:
	@mkdir -p build
	cat W3CTRMANIFEST|tail -n +2|xargs -I '{}' cp --parent '{}' build

.PHONY: check
check: build
	phantomjs --ignore-ssl-errors=true --ssl-protocol=tlsv1 $(SUPPORTDIR)/respec/tools/respec2html.js -e -w `cat W3CTRMANIFEST|head -1|cut -d '?' -f 1` build/output.html
	WIDLPROC_PATH=$(SUPPORTDIR)/widlproc/obj/widlproc python $(SUPPORTDIR)/webidl-checker/webidl-check build/output.html > /dev/null
	! (perl -T $(SUPPORTDIR)/linkchecker/bin/checklink -S 0  -q -b --suppress-broken 500 build/output.html |grep "^")
	html5validator --root build/
