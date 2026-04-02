# Contributing

This guide is for contributors and maintainers working on Wario itself.

## Development Setup

Install dependencies:

```sh
dart pub get
```

Run the CLI locally:

```sh
dart run wario --help
dart run wario sync
dart run wario exec -- git status --short
```

## Quality Checks

Before sending changes, run:

```sh
dart format --output=none --set-exit-if-changed bin lib test
dart analyze
dart test -r expanded
```

## CI

CI runs:

- formatting checks
- static analysis
- the full test suite

## Release Process

Releases are managed with `release-please` and Conventional Commits.

On each push to `main`, `release-please` inspects merged commits and maintains a release PR that updates:

- `pubspec.yaml`
- `CHANGELOG.md`
- `.release-please-manifest.json`

When that release PR is merged, `release-please` creates a GitHub release and pushes a `v<version>` tag.

For this repository, the tag format is `v1.2.3`. That should match the tag pattern configured for pub.dev trusted publishing.

Publishing to pub.dev is handled by `.github/workflows/publish.yml`, which is triggered by tags matching `v[0-9]+.[0-9]+.[0-9]+`.

### GitHub Token

Release automation uses Octo STS instead of a long-lived PAT.

The `octo-sts` GitHub App must be installed on this repository, and the trust policy for release automation lives in `.github/chainguard/release-please.sts.yaml`.

The release workflow exchanges the GitHub Actions OIDC token for a short-lived GitHub token scoped by that trust policy, then passes the resulting token to `release-please`.

The trust policy is intentionally bound to the `release-please` workflow on the `main` branch and to a dedicated OIDC audience so other workflows cannot reuse the same Octo STS identity by accident.

This keeps repo write credentials ephemeral while still allowing release tags to trigger downstream publish workflows.

### pub.dev Setup

In the `wario` package admin page on pub.dev, automated publishing from GitHub Actions should be configured for:

- repository: `JustinBeckwith/wario`
- tag pattern: `v{{version}}`

If you want an approval gate before publishing, require the `pub.dev` GitHub Actions environment on pub.dev and then uncomment the `environment: pub.dev` line in `.github/workflows/publish.yml`.

### Commit Message Format

Use Conventional Commits for any change that should appear in the changelog or affect versioning:

- `fix: ...` for patch releases
- `feat: ...` for minor releases
- `feat!: ...` or any commit with a `BREAKING CHANGE:` footer for major releases

Commits like `docs:`, `test:`, and `chore:` can still be included in release PRs, but they typically do not cause a release on their own.

### Bootstrap Note

`release-please` is bootstrapped from the current package version, `0.1.0`, via `.release-please-manifest.json`. That means future releases are calculated from the existing published version instead of treating the automation setup itself as a new release.

## Project Layout

- `bin/wario.dart`: CLI entrypoint and argument parsing
- `lib/config.dart`: config loading and validation
- `lib/sync.dart`: repo sync behavior
- `lib/exec.dart`: multi-repo command execution
- `lib/utils.dart`: GitHub repo discovery and auth lookup
- `test/`: CLI, config, sync, exec, and auth coverage
- `.github/chainguard/release-please.sts.yaml`: Octo STS trust policy for release automation
- `.github/workflows/publish.yml`: pub.dev trusted publishing workflow triggered by release tags
- `.github/workflows/release-please.yml`: release PR and GitHub release automation
- `release-please-config.json`: release-please package configuration
- `.release-please-manifest.json`: current released version tracked by release-please
