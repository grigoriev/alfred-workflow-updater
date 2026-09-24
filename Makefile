SCRIPTS    := update.sh autoupdate.sh
BUNDLE     := updater.tar.gz
PROVENANCE := updater.intoto.jsonl

# Lint and coverage tools, pinned by digest. Renovate keeps them current.
# renovate: datasource=docker depName=koalaman/shellcheck
SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d
# renovate: datasource=docker depName=kcov/kcov
KCOV_IMAGE       ?= kcov/kcov:latest@sha256:481289ae32e55e5b733019515acd10948a4f76dfed381765577db909664fc603

# ShellCheck runs in its pinned image. `make lint SHELLCHECK=shellcheck` uses a
# local one instead.
SHELLCHECK ?= docker run --rm -v "$(CURDIR):/mnt" -w /mnt $(SHELLCHECK_IMAGE)

.PHONY: all build test coverage lint clean \
	print-artifact print-release-files print-provenance print-version set-version

all: build

# Pack the scripts into the bundle that every workflow's `make updater` fetches
build:
	tar -czf $(BUNDLE) $(SCRIPTS)
	@echo "built $(BUNDLE)"

test:
	bats tests

# Run the tests under kcov, as the CI sonar job does, and convert the report
# for SonarCloud. kcov needs Linux, so it runs in its container. A failing
# test fails the target. The pattern matches update.sh and autoupdate.sh.
coverage:
	docker run --rm -v "$(CURDIR):$(CURDIR)" -w "$(CURDIR)" $(KCOV_IMAGE) bash -c \
		"apt-get update -qq && apt-get install -y -qq bats jq >/dev/null && kcov --include-pattern=update.sh coverage bats tests"
	python3 .github/coverage-to-sonar.py coverage sonar-coverage.xml
	@echo "== uncovered lines =="; grep 'covered="false"' sonar-coverage.xml || echo "(all covered)"

lint:
	$(SHELLCHECK) $(SCRIPTS)

# Names the CI and release workflows publish.
print-artifact:
	@echo $(BUNDLE)

print-release-files:
	@printf '%s\n' $(SCRIPTS) $(BUNDLE)

print-provenance:
	@echo $(PROVENANCE)

# The version lives in the git tags only. bump-version.yml and release.yml use
# these; there is no version file to write.
print-version:
	@v=$$(git describe --tags --abbrev=0 2>/dev/null) || v=v0.0.0; echo "$${v#v}"

set-version:
	@echo "the version lives in the git tags; no file to update"

clean:
	rm -rf $(BUNDLE) $(PROVENANCE) coverage sonar-coverage.xml
