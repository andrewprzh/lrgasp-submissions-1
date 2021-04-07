PYTHON = python3
FLAKE8 = python3 -m flake8
TWINE = ${PYTHON} -m twine

pyprogs = $(shell file -F $$'\t' bin/* devs/bin/* | awk '/Python script/{print $$1}')
pypi_url = https://upload.pypi.org/simple/
testpypi_url = https://test.pypi.org/simple/
testenv = testenv

version = $(shell PYTHONPATH=lib ${PYTHON} -c "import lrgasp; print(lrgasp.__version__)")

# mdl is an uncommon program to verify markdown
have_mdl = $(shell which -s mdl && echo yes || echo no)
have_mdlinkcheck = $(shell which -s markdown-link-check && echo yes || echo no)


help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "lint - check style with flake8"
	@echo "lint-doc - check documentation"
	@echo "lint-all - lint plus lint-doc"
	@echo "test - run tests quickly with the default Python"
	@echo "install - install the package to the active Python's site-packages"
	@echo "dist - package"
	@echo "test-pip - test install the package using pip"
	@echo "release-testpypi - test upload to testpypi"
	@echo "test-release-testpypi - install from testpypi"
	@echo "release - package and upload a release"
	@echo "test-release - test final release"


lint:
	${FLAKE8} ${pyprogs} lib

# requires the NPM packages:
#   remark-cli remark-lint remark-preset-lint-recommended markdown-link-check


lint-doc:  check-doc-format check-doc-links

lint-all: lint lint-doc

ifeq (${have_mdl},yes)
check-doc-format:
	mdl --style=mdl-style.rb README.md docs/
else
check-doc-format:
	@echo "Note: mdl not installed, not linting markdown" >&2
endif

ifeq (${have_mdlinkcheck},yes)
mdfiles = $(wildcard README.md docs/*.md)
check-doc-links: ${mdfiles:%=check-doc-links_%}
check-doc-links_%:
	markdown-link-check --config=markdown-link-check.json $*
check-doc-links_docs/%:
	markdown-link-check --config=markdown-link-check.json docs/$*
else
check-doc-links:
	@echo "Note: markdown-link-check not installed, not checking markdown links" >&2
endif

test:
	cd tests && ${MAKE} test

clean: test_clean
	rm -rf build/ dist/ ${testenv}/ lib/lrgasp_tools.egg-info/ lib/lrgasp/__pycache__/

test_clean:
	cd tests && ${MAKE} clean

define envsetup
	@rm -rf ${testenv}/
	mkdir -p ${testenv}
	${PYTHON} -m virtualenv --quiet ${testenv}
endef
envact = source ${testenv}/bin/activate

dist_tar = dist/lrgasp-tools-${version}.tar.gz
dist_whl = dist/lrgasp_tools-${version}-py3-none-any.whl
pkgver_spec = lrgasp-tools==${version}

dist: clean
	${PYTHON} setup.py sdist
	${PYTHON} setup.py bdist_wheel
	@ls -l ${dist_tar}
	@ls -l ${dist_whl}

# test install locally
test-pip: dist
	${envsetup}
	${envact} && pip install --no-cache-dir ${dist_tar}
	${envact} && ${MAKE} test

# test release to testpypi
release-testpypi: dist
	${TWINE} upload --repository=testpypi ${dist_whl} ${dist_tar}

# test release install from testpypi, testpypi doesn't have requeiments, so install them first
test-release-testpypi:
	${envsetup}
	${envact} && pip install --no-cache-dir --index-url=${testpypi_url} --extra-index-url=https://pypi.org/simple ${pkgver_spec}
	${envact} && ${MAKE} test

release: dist
	${TWINE} upload --repository=pypi ${dist_whl} ${dist_tar}

release-test:
	${envsetup}
	${envact} && pip install --no-cache-dir ${pkgver_spec}
	${envact} && ${MAKE} test

