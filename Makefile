VERSION = 2.0.0
NPM_ROOT = node_modules
STATIC_DIR = src/sentry/static/sentry
BOOTSTRAP_JS = ${STATIC_DIR}/scripts/lib/bootstrap.js
BOOTSTRAP_JS_MIN = ${STATIC_DIR}/scripts/lib/bootstrap.min.js
UGLIFY_JS ?= node_modules/uglify-js/bin/uglifyjs

develop: update-submodules
	npm install -q
	pip install -q "file://`pwd`#egg=sentry[dev]"
	pip install -q "file://`pwd`#egg=sentry[tests]"
	pip install -q -e . --use-mirrors

dev-postgres:
	pip install -q "file://`pwd`#egg=sentry[dev]"
	pip install -q "file://`pwd`#egg=sentry[postgres]"
	pip install -q -e . --use-mirrors

dev-mysql:
	pip install -q "file://`pwd`#egg=sentry[dev]"
	pip install -q "file://`pwd`#egg=sentry[mysql]"
	pip install -q -e . --use-mirrors

build: locale

clean:
	rm -r src/sentry/static/CACHE

locale:
	cd src/sentry && sentry makemessages -l en
	cd src/sentry && sentry compilemessages

update-transifex:
	pip install transifex-client
	tx push -s
	tx pull -a

compile-bootstrap-js:
	@cat src/bootstrap/js/bootstrap-transition.js src/bootstrap/js/bootstrap-alert.js src/bootstrap/js/bootstrap-button.js src/bootstrap/js/bootstrap-carousel.js src/bootstrap/js/bootstrap-collapse.js src/bootstrap/js/bootstrap-dropdown.js src/bootstrap/js/bootstrap-modal.js src/bootstrap/js/bootstrap-tooltip.js src/bootstrap/js/bootstrap-popover.js src/bootstrap/js/bootstrap-scrollspy.js src/bootstrap/js/bootstrap-tab.js src/bootstrap/js/bootstrap-typeahead.js src/bootstrap/js/bootstrap-affix.js ${STATIC_DIR}/scripts/bootstrap-datepicker.js > ${BOOTSTRAP_JS}
	${UGLIFY_JS} -nc ${BOOTSTRAP_JS} > ${BOOTSTRAP_JS_MIN};

install-test-requirements:
	pip install -q "file://`pwd`#egg=sentry[tests]"

update-submodules:
	git submodule init
	git submodule update

test: install-test-requirements lint test-js test-python test-cli

testloop: install-test-requirements
	pip install pytest-xdist --use-mirrors
	py.test tests -f

test-cli:
	@echo "Testing CLI"
	rm -f test.conf
	sentry init test.conf
	sentry --config=test.conf help | grep start > /dev/null

test-js:
	@echo "Running JavaScript tests"
	${NPM_ROOT}/phantomjs/bin/phantomjs runtests.js tests/js/index.html
	@echo ""

test-python:
	@echo "Running Python tests"
	python setup.py -q test || exit 1
	@echo ""

lint: lint-python lint-js

lint-python:
	@echo "Linting Python files"
	flake8 --exclude=migrations,src/sentry/static/CACHE/* --ignore=E501,E225,E121,E123,E124,E125,E127,E128 src/sentry
	@echo ""

lint-js:
	@echo "Linting JavaScript files"
	@${NPM_ROOT}/jshint/bin/hint src/sentry/ || exit 1
	@echo ""

coverage: install-test-requirements
	py.test --cov=src/sentry --cov-report=html


.PHONY: build
