# Security policy

## Reporting a vulnerability

Report a vulnerability privately through GitHub:
https://github.com/grigoriev/alfred-workflow-updater/security/advisories/new
(the **Security** tab, **Report a vulnerability**). Do not open a public issue for it.

We answer within a week. The fix goes into the next release, and its release notes name it.

## Supported versions

Only the latest release gets fixes.

## Scope

`update.sh`, `autoupdate.sh`, the `Makefile` and the GitHub Actions workflows belong to this
repository. Every Alfred workflow of this owner bundles these scripts, so a fix here reaches them
on their next release.

Vulnerabilities in upstream software (Alfred, `curl`, `jq`, the GitHub API) belong to the upstream project. Tell us as well
if this project is affected, so we can release a fix when the upstream fix is out.
