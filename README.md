# reusable-workflows

ActionsCI's shared, reusable GitHub Actions workflows.

## Workflows

| File | Purpose |
|---|---|
| `build-eks.yaml` | Orchestrates docker build/push, helm package/push, and GitOps deploy for EKS services |
| `build-eks-pr-test.yaml` | PR smoke: dispatches `django-angular-boilerplate` to run the PR's `build-eks.yaml` against a throwaway `pr-test/<n>` branch in `ActionsCI/gitops` |
| `pre-build.yaml`, `pre-build-simple.yaml` | Parse `cicd.yaml` and compute image/chart versions |
| `docker-build-push.yaml` (ECR), `docker_build_push.yaml` (GCR) | Build and push container images |
| `docker-build-test.yaml` | Credential-free PR gate: builds the Dockerfile without pushing |
| `helm_package_push.yaml` | Package and publish Helm charts to ECR |
| `service-deployment-gitops.yaml` | Updates `Chart.yaml` in `ActionsCI/gitops`; `target_branch` input routes non-main writes |
| `gcp_cloudrun_deploy.yaml`, `deploy_cloud_run.yaml` | Deploy to GCP Cloud Run |
| `compute_next_semver.yaml`, `version-incrementor.yaml` | SemVer helpers |
| `success-check.yaml` | Aggregate `needs.*` conclusions |

## Standard: pin all third-party actions to a commit SHA

All `uses:` references to **third-party** actions (anything outside `ActionsCI/`) must pin to a 40-character commit SHA, not a tag.

### Format

```yaml
- uses: owner/action@<40-char-sha>  # vX.Y.Z
```

Example:

```yaml
- uses: actions/checkout@08eba0b27e820071cde6df949e0beb9ba4906955  # v4.3.0
```

The trailing `# vX.Y.Z` comment is required so the pin is readable and upgrades are reviewable.

### Why

1. **Supply-chain security.** Tags are mutable: a compromised maintainer account (or a malicious PR merged upstream) can silently re-point `@v4` to arbitrary code, and every consumer picks it up on the next run. This is not hypothetical — the `tj-actions/changed-files` compromise in March 2025 affected tens of thousands of repos that pinned to a tag. A commit SHA is immutable: only the code you reviewed when you pinned ever runs.
2. **Auditability.** Any change to what actually executes in CI shows up as a git diff (SHA changes), not as silent drift behind a moving tag.
3. **Internal trust / forkability.** Because every pin is a concrete commit, this repo can be cloned, vendored, or mirrored to a hardened internal fork with no hidden dependency on mutable upstream refs. The reviewed code is the code that runs.
4. **Reproducibility.** A re-run of a year-old job executes the exact same action code regardless of what has happened upstream.

### Tradeoff: upgrades are manual

SHA pinning trades automatic upgrades for explicit ones:

- **No free CVE patches.** When an upstream ships a security fix, you get it only when someone bumps the SHA here.
- **Drift monitoring is on us.** Dependabot understands SHA pins and will open bump PRs — but only if it's enabled.
- **Every bump is a PR.** Reviewer skims the upstream release notes and the diff, then approves. Treat action upgrades like any other dependency upgrade.

Enable Dependabot in `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

### What is pinned vs. not

- **Third-party actions** (`actions/*`, `docker/*`, `google-github-actions/*`, etc.) — **always pin to SHA.**
- **Internal `ActionsCI/*` actions** (e.g. `ActionsCI/compute-semver`, `ActionsCI/docker-build-push`) — may remain on `@main` because the org owns the upstream and enforces branch protections. Pin to SHA when reproducibility matters.
- **Same-repo reusable workflows** (`uses: ./.github/workflows/foo.yaml`) — implicitly pinned to the caller's ref; no SHA needed.
- **Cross-repo reusable workflows** (`uses: actionsci/reusable-workflows/.github/workflows/foo.yaml@<ref>`) — the ref should be a SHA or a release tag controlled by the consumer. `@main` is acceptable only for non-production callers (e.g. `pr-smoke-build-eks.yaml` in `django-angular-boilerplate`, which is dispatched with an explicit PR SHA).

### How to add or bump a pin

1. Pick the upstream tag you want (e.g. `v4.3.0`).
2. Resolve it to a commit SHA — either via `git ls-remote https://github.com/<owner>/<repo> refs/tags/<tag>` or by copying the full SHA from the release page.
3. Write it as `owner/repo@<sha>  # v<tag>`.
4. Link the upstream release notes in the PR description so the reviewer can skim the diff.

### Enforcement

Currently a review-time rule. A future PR will add a lint check that fails CI on any `uses: <third-party>/<action>@v\d` or `@<branch>` reference.
