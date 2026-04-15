CONTAINER_PREFIX=ghcr.io/nhsdigital/eps-devcontainers/

ifeq ($(strip $(NO_CACHE)),true)
NO_CACHE_FLAG=--no-cache
endif

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

.PHONY: install install-python install-node install-hooks build-base-image build-node-24-image build-node-24-python-3-10-image build-node-24-python-3-12-image build-node-24-python-3-13-image build-node-24-python-3-14-image \
	build-eps-storage-terraform-image build-eps-data-extract-image build-fhir-facade-image build-node-24-python-3-14-golang-1-24-image build-node-24-python-3-14-java-24-image \
	build-regression-tests-image build-all build-image build-githubactions-image scan-image scan-image-json shell-image lint test lint-githubactions lint-githubaction-scripts clean \
	build-syft build-grype build-grant build-tflint build-tools build-zizmor
install: install-python install-node install-hooks

install-python:
	poetry install

install-node:
	npm ci --ignore-scripts

install-hooks: install-python
	poetry run pre-commit install --install-hooks --overwrite

build-base-image:
	CONTAINER_NAME=base BASE_VERSION_TAG=local-build BASE_FOLDER=. IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-image:
	CONTAINER_NAME=node_24 BASE_VERSION_TAG=local-build BASE_FOLDER=base_node IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-10-image:
	CONTAINER_NAME=node_24_python_3_10 BASE_VERSION_TAG=local-build BASE_FOLDER=languages IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-12-image:
	CONTAINER_NAME=node_24_python_3_12 BASE_VERSION_TAG=local-build BASE_FOLDER=languages IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-13-image:
	CONTAINER_NAME=node_24_python_3_13 BASE_VERSION_TAG=local-build BASE_FOLDER=languages IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-14-image:
	CONTAINER_NAME=node_24_python_3_14 BASE_VERSION_TAG=local-build BASE_FOLDER=languages IMAGE_TAG=local-build $(MAKE) build-image

build-eps-storage-terraform-image:
	CONTAINER_NAME=eps-storage-terraform BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-eps-data-extract-image:
	CONTAINER_NAME=eps_data_extract BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-fhir-facade-image:
	CONTAINER_NAME=fhir_facade_api BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-14-golang-1-24-image:
	CONTAINER_NAME=node_24_python_3_14_golang_1_24 BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-node-24-python-3-14-java-24-image:
	CONTAINER_NAME=node_24_python_3_14_java_24 BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-regression-tests-image:
	CONTAINER_NAME=regression_tests BASE_VERSION_TAG=local-build BASE_FOLDER=projects IMAGE_TAG=local-build $(MAKE) build-image

build-all: build-base-image build-node-24-image build-node-24-python-3-10-image build-node-24-python-3-12-image build-node-24-python-3-13-image build-node-24-python-3-14-image \
	build-eps-storage-terraform-image build-eps-data-extract-image build-fhir-facade-image build-node-24-python-3-14-golang-1-24-image build-node-24-python-3-14-java-24-image \
	build-regression-tests-image

build-syft:
	@if docker image inspect local_syft:latest >/dev/null 2>&1; then \
		echo "Image local_syft:latest already exists. Skipping build."; \
	else \
		docker build -f src/base/.devcontainer/Dockerfile.syft --tag local_syft:latest src/base/.devcontainer/; \
	fi
build-grype:
	@if docker image inspect local_grype:latest >/dev/null 2>&1; then \
		echo "Image local_grype:latest already exists. Skipping build."; \
	else \
		docker build -f src/base/.devcontainer/Dockerfile.grype --tag local_grype:latest src/base/.devcontainer/; \
	fi

build-grant:
	@if docker image inspect local_grant:latest >/dev/null 2>&1; then \
		echo "Image local_grant:latest already exists. Skipping build."; \
	else \
		docker build -f src/base/.devcontainer/Dockerfile.grant --tag local_grant:latest src/base/.devcontainer/; \
	fi

build-tflint:
	@if docker image inspect local_tflint:latest >/dev/null 2>&1; then \
		echo "Image local_tflint:latest already exists. Skipping build."; \
	else \
		docker buildx build \
			--secret id=GH_TOKEN,env=GITHUB_TOKEN \
			-f src/base/.devcontainer/Dockerfile.tflint \
			--tag local_tflint:latest \
			src/base/.devcontainer/; \
	fi

build-zizmor:
	@if docker image inspect local_zizmor:latest >/dev/null 2>&1; then \
		echo "Image local_zizmor:latest already exists. Skipping build."; \
	else \
		docker buildx build \
			--secret id=GH_TOKEN,env=GITHUB_TOKEN \
			-f src/base/.devcontainer/Dockerfile.zizmor \
			--tag local_zizmor:latest \
			src/base/.devcontainer/; \
	fi

build-tools: build-syft build-grype build-grant build-tflint build-zizmor

build-image: build-syft build-grype build-grant build-tflint guard-CONTAINER_NAME guard-BASE_VERSION_TAG guard-BASE_FOLDER guard-IMAGE_TAG
	workspace_folder="$${CONTAINER_NAME}"; \
	case "$${CONTAINER_NAME}" in \
		eps_*) workspace_folder="$$(printf '%s' "$${CONTAINER_NAME}" | tr '_' '-')" ;; \
	esac; \
	npx devcontainer build \
		--workspace-folder ./src/$${BASE_FOLDER}/$${workspace_folder} \
		$(NO_CACHE_FLAG) \
		--push false \
		--output type=image,name="${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}",push=false,compression=zstd \
		--cache-from "${CONTAINER_PREFIX}$${CONTAINER_NAME}:latest" \
		--image-name "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}"

build-githubactions-image: guard-BASE_IMAGE_NAME guard-BASE_IMAGE_TAG guard-IMAGE_TAG
	docker buildx build \
		-f src/githubactions/Dockerfile \
		$(NO_CACHE_FLAG) \
		--build-arg BASE_IMAGE_NAME="$${BASE_IMAGE_NAME}" \
		--build-arg BASE_IMAGE_TAG="$${BASE_IMAGE_TAG}" \
		--load \
		-t "${CONTAINER_PREFIX}$${BASE_IMAGE_NAME}:githubactions-$${IMAGE_TAG}" \
		.
scan-image: guard-CONTAINER_NAME guard-BASE_FOLDER guard-IMAGE_TAG
	grype "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}" \
		--scope all-layers \
		--sort-by severity \
		--fail-on high

scan-image-json: guard-CONTAINER_NAME guard-BASE_FOLDER guard-IMAGE_TAG
	grype "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}" \
		--scope all-layers \
		--output json \
		--file ".grype_out/grype_${CONTAINER_NAME}_${IMAGE_TAG}.json" 

shell-image: guard-CONTAINER_NAME guard-IMAGE_TAG
	docker run -it \
	--rm \
	"${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}"  \
	bash

lint: lint-githubactions

test:
	echo "Not implemented"

lint-githubactions:
	actionlint

lint-githubaction-scripts:
	shellcheck .github/scripts/*.sh

clean:
	rm -rf .out

%:
	@$(MAKE) -f /usr/local/share/eps/Mk/common.mk $@
