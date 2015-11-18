# webrtc-respec-ci

Script to run continuous integration on a [respec](https://github.com/w3c/respec)-based specification.

## Description

This Makefile can be used with the [Travis CI](https://travis-ci.org/) continuous integration system (within a `.travis.yml` file) or locally from a Debian-based system before contributing to a specification maintained by the [W3C WebRTC WG](http://www.w3.org/2011/04/webrtc/).

## Commands

`setup` _(to be used locally)_ - Setup dependencies on Debian-based system

`update` _(to be used locally)_ - Update dependencies on Debian-based system

`travissetup` _(to be used on Travis)_ - Setup dependencies on Travis CI

`check` - Run the following checks on your respec document:
* Check line wrapping using [tidy-html5](https://github.com/htacg/tidy-html5). Optional enable it with `LINEWRAP=true`
* [respec](https://github.com/w3c/respec) validity
* [WebIDL](http://www.w3.org/TR/WebIDL/) validity using [widlproc](https://github.com/dontcallmedom/widlproc)
* HTML5 validity of the generated file using [html5validator/Nu Html Checker](https://github.com/validator/validator)
* Check internal links using [linkchecker](https://github.com/dontcallmedom/linkchecker)

`linewrap` - Line wrapping. Defaults to 100 chars lines, set desired length with `LINEWRAPLENGTH=xx`


## Usage

### Local use

```bash
cd WebRTC
git clone git@github.com:w3c/webrtc-respec-ci.git
git clone git@github.com:w3c/mediacapture-main.git
cd mediacapture-main
make -f ../webrtc-respec-ci/Makefile setup
make -f ../webrtc-respec-ci/Makefile check
```

### With Travis

Example `.travis.yml` file using [Travis CI's new container-based infrastructure](http://docs.travis-ci.com/user/workers/container-based-infrastructure/).

```
language: python
python:
  - "2.7_with_system_site_packages"
sudo: false
addons:
  apt:
    packages:
      - libwww-perl
      - libcss-dom-perl
      - python-lxml
install:
 - git clone https://github.com/w3c/webrtc-respec-ci.git
 - make -f webrtc-respec-ci/Makefile travissetup
script:
 - make -f webrtc-respec-ci/Makefile check
```

### Line wrapping

This script can help you ensure that your modifications do not break line wrapping of the original document.

Line wrapping using default line length:
```bash
make -f ../webrtc-respec-ci/Makefile linewrap
```

Line wrapping using custom line length:
```bash
make -f ../webrtc-respec-ci/Makefile linewrap LINEWRAPLENGTH=80
```
