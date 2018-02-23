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

`tidy` - Cleanup your document markup using [tidy-html5](https://github.com/htacg/tidy-html5)


## Usage

### Local use

Example usage on the [Media Capture and Streams specification](https://github.com/w3c/mediacapture-main/)

```bash
git clone git@github.com:w3c/mediacapture-main.git
cd mediacapture-main
make setup
make check
```

The `mediacapture-main/Makefile` script will take care of installing and setting up `webrtc-respec-ci` and its dependencies automatically.

### With Travis

Example `.travis.yml` file using [Travis CI's Container-based infrastructure](https://docs.travis-ci.com/user/reference/overview/#Virtualization-environments).

```yaml
language: python

dist: trusty

branches:
  only:
    - /.*/

sudo: false

addons:
  apt:
    packages:
      - libwww-perl
      - libcss-dom-perl
  chrome: stable

cache:
  directories:
    - node_modules # NPM packages

before_install:
  - nvm install lts/*

install:
 - make travissetup

script:
 - make check
```

### Line wrapping

This script can help you ensure that your modifications do not break line wrapping of the original document.

Check line wrapping _(using default line length of 100 characters defined in webrtc-respec-ci/tidy.config)_:
```bash
LINEWRAP=true make tidycheck
```

You can define a specific line length for your document by editing `tidy.config` and setting the `wrap` option to the desired line length eg `wrap: 80`.
