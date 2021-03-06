BASEDIR ?= $(PWD)
SHASUM ?= shasum -p -a 256
OS = $(shell uname | tr '[A-Z]' '[a-z]')
DCOS_PACKAGE_NAME ?= "dcos-riak-$(OS)"

all: test packages
dev: activate-env test packages

clean:
	rm -rf $(BASEDIR)/.tox $(BASEDIR)/env $(BASEDIR)/build $(BASEDIR)/dist
	echo "Deleted virtualenv and test artifacts."

env:
	virtualenv -q $(BASEDIR)/env --prompt='(riak-mesos) '
	echo "Virtualenv created."

activate-env: env
	$(shell source $(BASEDIR)/env/bin/activate)
	echo "Virtualenv activated."

deps:
	pip install -r $(BASEDIR)/requirements.txt
	pip install -e $(BASEDIR)
	echo "Requirements installed."

test: deps
	tox -e py27-integration

test-end-to-end: deps
	tox -e py27-end-to-end

packages: deps
	python setup.py bdist_wheel
	python setup.py sdist

docs:
	cat README.md | pandoc --from markdown_github --to rst > README.rst

build:
	pip install pyinstaller==3.1.1
	pyinstaller binary.spec
	mv $(BASEDIR)/dist/dcos-riak $(BASEDIR)/dist/$(DCOS_PACKAGE_NAME)
	$(SHASUM) $(BASEDIR)/dist/$(DCOS_PACKAGE_NAME) | head -c 64 > $(BASEDIR)/dist/$(DCOS_PACKAGE_NAME)-sha256-sum.txt

clear-build:
	rm -rf $(BASEDIR)/build || true
	rm -rf $(BASEDIR)/dist || true

rebuild: clear-build build

# Syntax / Test Checklist
# pip install pytest
# py.test -vv tests/integration
# pip install flake8
# flake8 --verbose riak_mesos tests
# pip install isort
# isort --recursive --verbose riak_mesos tests
# isort --recursive --check-only --diff --verbose riak_mesos tests
