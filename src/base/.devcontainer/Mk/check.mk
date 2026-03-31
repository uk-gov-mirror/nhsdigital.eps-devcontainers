.PHONY: lint test shellcheck cfn-lint cdk-synth cfn-guard-sam-templates cfn-guard-cloudformation cfn-guard-cdk cfn-guard-terraform zizmor
lint:
	echo "Not implemented"
	exit 1

test:
	echo "Not implemented"
	exit 1

shellcheck:
	@if find .github/scripts -maxdepth 1 -type f -name "*.sh" | grep -q .; then \
		shellcheck .github/scripts/*.sh; \
	fi
	@if find scripts -maxdepth 1 -type f -name "*.sh" | grep -q .; then \
		shellcheck scripts/*.sh; \
	fi

cfn-lint:
	@if find cloudformation -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | grep -q .; then \
		cfn-lint -I "cloudformation/**/*.y*ml" 2>&1 | awk '/Run scan/ { print } /^[EW][0-9]/ { print; getline; print; found=1 } END { exit found }'; \
	fi
	@if find SAMtemplates -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | grep -q .; then \
		cfn-lint -I "SAMtemplates/**/*.y*ml" 2>&1 | awk '/Run scan/ { print } /^[EW][0-9]/ { print; getline; print; found=1 } END { exit found }'; \
	fi

cdk-synth:
	echo "Not implemented"
	exit 1

cfn-guard-sam-templates:
	@bash -eu -o pipefail -c '\
		rulesets=("ncsc" "ncsc-cafv3" "wa-Reliability-Pillar" "wa-Security-Pillar"); \
		mkdir -p .cfn_guard_out; \
		for ruleset in "$${rulesets[@]}"; do \
			while IFS= read -r -d "" file; do \
				SAM_OUTPUT=$$(sam validate -t "$$file" --region eu-west-2 --debug 2>&1 | grep -Pazo "(?s)AWSTemplateFormatVersion.*\\n/" | tr -d "\\0"); \
				output_file=".cfn_guard_out/$${file}_$${ruleset}.txt"; \
				mkdir -p "$$(dirname "$$output_file")"; \
				echo "$${SAM_OUTPUT::-1}" | /home/vscode/.guard/bin/cfn-guard validate --rules "/usr/local/share/eps/cfnguard_rulesets/output/$$ruleset.guard" --show-summary fail > "$$output_file"; \
			done < <(find ./SAMtemplates -type f \( -name "*.yaml" -o -name "*.yml" \) -print0); \
		done\
	'

cfn-guard-cloudformation:
	@bash -eu -o pipefail -c '\
		rulesets=("ncsc" "ncsc-cafv3" "wa-Reliability-Pillar" "wa-Security-Pillar"); \
		mkdir -p .cfn_guard_out; \
		for ruleset in "$${rulesets[@]}"; do \
			/home/vscode/.guard/bin/cfn-guard validate \
				--data cloudformation \
				--rules "/usr/local/share/eps/cfnguard_rulesets/output/$$ruleset.guard" \
				--show-summary fail \
				> ".cfn_guard_out/cloudformation_$$ruleset.txt"; \
		done\
	'

cfn-guard-cdk:
	@bash -eu -o pipefail -c '\
		rulesets=("ncsc" "ncsc-cafv3" "wa-Reliability-Pillar" "wa-Security-Pillar"); \
		mkdir -p .cfn_guard_out; \
		for ruleset in "$${rulesets[@]}"; do \
			/home/vscode/.guard/bin/cfn-guard validate \
				--data cdk.out \
				--rules "/usr/local/share/eps/cfnguard_rulesets/output/$$ruleset.guard" \
				--show-summary fail \
				> ".cfn_guard_out/cdk_$$ruleset.txt"; \
		done\
	'

cfn-guard-terraform:
	@bash -eu -o pipefail -c '\
		rulesets=("ncsc" "ncsc-cafv3" "wa-Reliability-Pillar" "wa-Security-Pillar"); \
		mkdir -p .cfn_guard_out; \
		for ruleset in "$${rulesets[@]}"; do \
			/home/vscode/.guard/bin/cfn-guard validate \
				--data terraform_plans \
				--rules "/usr/local/share/eps/cfnguard_rulesets/output/$$ruleset.guard" \
				--show-summary fail \
				> ".cfn_guard_out/terraform_$$ruleset.txt"; \
		done\
	'

actionlint:
	actionlint

secret-scan:
	git-secrets --scan-history .

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

zizmor:
	zizmor --min-severity medium .

syft-generate-sbom:
	syft \
		--output cyclonedx-json=.sbom/sbom.cdx.json \
		dir:./

syft-generate-sbom-dev-dependencies:
	SYFT_JAVASCRIPT_INCLUDE_DEV_DEPENDENCIES=true \
	syft \
		--output cyclonedx-json=.sbom/sbom.dev.cdx.json \
		dir:./

grype-scan: syft-generate-sbom
	grype \
		--fail-on high \
		.sbom/sbom.cdx.json 

grype-scan-dev-dependencies: syft-generate-sbom-dev-dependencies
	grype \
		--fail-on high \
		.sbom/sbom.dev.cdx.json 

grype-scan-json: syft-generate-sbom
	grype \
		--fail-on high \
		.sbom/sbom.cdx.json \
		--output json=".sbom/grype_analysis.json"

grype-scan-json-dev-dependencies: syft-generate-sbom-dev-dependencies
	grype \
		--fail-on high \
		.sbom/sbom.dev.cdx.json \
		--output json=".sbom/grype_analysis.dev.json"

grype-scan-local:
	grype \
		--fail-on high \
		.

grype-scan-docker-image: guard-DOCKER_IMAGE
	grype "${DOCKER_IMAGE}" \
		--scope all-layers \
		--sort-by severity \
		--fail-on high

grant-scan: syft-generate-sbom
	grant check \
		.sbom/sbom.cdx.json

grant-scan-dev-dependencies: syft-generate-sbom-dev-dependencies
	grant check \
		.sbom/sbom.dev.cdx.json

grant-scan-json: syft-generate-sbom
	grant check .sbom/sbom.cdx.json \
		--output json \
		--quiet \
		--output-file ".sbom/grant_analysis.json"

grant-scan-json-dev-dependencies: syft-generate-sbom-dev-dependencies
	grant check .sbom/sbom.dev.cdx.json \
		--output json \
		--quiet \
		--output-file ".sbom/grant_analysis.dev.json"
