### Modifiable variables ###
version := 20230210

build_image := riazarbi/rblncr_demo:$(version)
build_source := riazarbi/maker:$(version)

debug_image := riazarbi/rblncr_demo_debug:$(version)
debug_source := riazarbi/maker_binder:$(version)

build_run := docker run --rm --user root --mount type=bind,source="$(shell pwd)/",target=/home/maker/  $(build_image)
debug_run := docker run --rm -p 8888:8888 --mount type=bind,source="$(shell pwd)/",target=/home/maker $(debug_image)

### Generic targets DO NOT MODIFY ###

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build docker container with required dependencies and data
	docker build -t $(build_image) --no-cache --build-arg FROMIMG=$(build_source) .

.PHONY: pull
pull: ## Pull build image from docker hub
	docker pull $(build_image)

.PHONY: push
push: build build-debug ## Pull build image from docker hub
	docker push $(build_image)

.PHONY: build-debug
build-debug: ## Build docker debug container with required dependencies
	docker build -t $(debug_image) --no-cache --build-arg FROMIMG=$(debug_source) .

.PHONY: test
test: ## Run tests
	$(build_run) R -e 'print("Image Runs")'

.PHONY: clean
clean: ## Remove build files
	rm -rf .cache .config .ipython .jupyter .local .Rhistory .Rproj.user

.PHONY: debug
debug:  ## Launch an interactive environment
	$(debug_run) jupyter notebook --NotebookApp.default_url=/lab/ --no-browser --ip=0.0.0.0 --port=8888

### Repo-specific targets ###

.PHONY:
run: ## Run main routine
	$(build_run) /bin/bash run.sh

