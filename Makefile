PYTHON = python3
FLAKE8 = python3 -m flake8
TWINE = ${PYTHON} -m twine

pyprogs = $(shell file -F $$'\t' bin/* | awk '/Python script/{print $$1}')
pypi_url = https://upload.pypi.org/simple/
testpypi_url = https://test.pypi.org/simple/
testenv = testenv

version = $(shell PYTHONPATH=lib ${PYTHON} -c "import lrgasp; print(lrgasp.__version__)")

# mdl is an uncommon program to verify markdown
have_mdl = $(shell which -s mdl && echo yes || echo no)

help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "lint - check style with flake8"
	@echo "test - run tests quickly with the default Python"
	@echo "install - install the package to the active Python's site-packages"
	@echo "dist - package"
	@echo "test-pip - test install the package using pip"
	@echo "release-testpypi - test upload to testpypi"
	@echo "test-release-testpypi - install from testpypi"
	@echo "release - package and upload a release"
	@echo "test-release - test final release"


lint: lint_code lint_doc
lint_code:
	${FLAKE8} ${pyprogs} lib
# requires https://github.com/markdownlint/markdownlint
lint_doc:
ifeq (${have_mdl},yes)
	mdl --style=mdl-style.rb docs/
else
	@echo "Note: mdl not installed, not linting metadata"
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

dist: clean
	${PYTHON} setup.py sdist
	${PYTHON} setup.py bdist_wheel
	ls -l dist

# test install locally
test-pip: dist
	${envsetup}
	${envact} && pip install --no-cache-dir dist/lrgasp-tools-${version}.tar.gz
	${envact} && ${MAKE} test

# test release to testpypi
release-testpypi: dist
	${TWINE} upload --repository=testpypi dist/lrgasp_tools-${version}.whl dist/lrgasp-tools-${version}.tar.gz

# test release install from testpypi, testpypi doesn't have requeiments, so install them first
test-release-testpypi:
	${envsetup}
	${envact} && pip install --no-cache-dir --index-url=${testpypi_url} --extra-index-url=https://pypi.org/simple 'lrgasp-tools==${version}'
	${envact} && ${MAKE} test

release: dist
	${TWINE} upload --repository=pypi dist/lrgasp_tools-${version}.whl dist/lrgasp-tools-${version}.tar.gz

release-test:
	${envsetup}
	${envact} && pip install --no-cache-dir 'lrgasp-tools==${version}'
	${envact} && ${MAKE} test

