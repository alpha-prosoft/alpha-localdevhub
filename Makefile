.PHONY := setup build clean deploy

SHELL := /bin/bash

# S3 bucket for Lambda deployment
S3_BUCKET ?= your-deployment-bucket
STACK_NAME ?= localdevhub-lambda

# Optional pip index URL for custom package repositories
# Usage: make build PIP_INDEX_URL=https://your-private-pypi/simple
PIP_INDEX_URL ?=

setup:
	rm -rf .venv &&\
		python3 -m venv .venv &&\
		source .venv/bin/activate &&\
		if [ -n "$(PIP_INDEX_URL)" ]; then \
			pip3 install --index-url $(PIP_INDEX_URL) -r requirements.txt; \
		else \
			pip3 install -r requirements.txt; \
		fi

build:
	@echo "Building Lambda packages with Docker..."
	@chmod +x build.sh
	@if [ -n "$(PIP_INDEX_URL)" ]; then \
		echo "Using custom pip index: $(PIP_INDEX_URL)"; \
		PIP_INDEX_URL="$(PIP_INDEX_URL)" ./build.sh; \
	else \
		./build.sh; \
	fi

clean:
	rm -rf dist/
	rm -rf .venv/
	rm -rf __pycache__/

