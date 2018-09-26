.PHONY: help doc

all: help
	@echo "\nTry something...\n"

install: ## Prepare the host sytem for development
	# install FoundationDB
	wget https://www.foundationdb.org/downloads/5.2.5/ubuntu/installers/foundationdb-clients_5.2.5-1_amd64.deb
	sudo dpkg -i foundationdb-clients_5.2.5-1_amd64.deb
	wget https://www.foundationdb.org/downloads/5.2.5/ubuntu/installers/foundationdb-server_5.2.5-1_amd64.deb
	sudo dpkg -i foundationdb-server_5.2.5-1_amd64.deb
	# Proceed with python dependencies
	pip3 install pipenv --upgrade
	pipenv install --dev --skip-lock
	cd src && pipenv run python found_build.py
	pipenv run pre-commit install

check: ## Run tests
	pipenv run py.test -vv --capture=no src/tests/
	make database-clean
	pipenv check
	bandit --skip=B101 -r src/
	@echo "\033[95m\n\nYou may now run 'make lint' or 'make coverage'.\n\033[0m"

coverage: ## Code coverage
	pipenv run py.test -vv --cov-config .coveragerc --cov-report term --cov-report html --cov-report xml --cov=src src/tests/
	make database-clean

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

devrun: ## Run application in development mode
	cd src && DEBUG=DEBUG adev runserver --livereload --static socialite/static/ socialite/socialite.py

lint: ## Lint the code
	pipenv run pylint src/

doc: ## Build the documentation
	cd doc && make html
	@echo "\033[95m\n\nBuild successful! View the docs homepage at doc/_build/html/index.html.\n\033[0m"

upstream: ## Clone the most important third-party libraries
	mkdir upstream
	git clone https://github.com/aio-libs/aiohttp upstream/aiohttp
	git clone https://github.com/Deepwalker/trafaret upstream/trafaret

clean: ## Clean up
	git clean -fX

database-clean:  ## Remove all data from the database
	fdbcli --exec "writemode on; clearrange \x00 \xFF;"

todo: ## Things that should be done
	@grep -nR --color=always TODO src/

xxx: ## Things that require attention
	@grep -nR --color=always --before-context=2  --after-context=2 XXX src/
