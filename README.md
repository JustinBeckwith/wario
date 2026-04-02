# Wario

Wario is a small Dart CLI for working across many GitHub repositories at once.

It does two things well:

- `wario sync` clones or updates a managed set of repositories into one local root
- `wario exec` runs the same command across every cloned repository, with bounded concurrency

Wario is useful when you regularly touch a whole org, a curated repo set, or a combination of public and private repositories.

## Requirements

- Dart 3
- Git
- GitHub access for any private or internal repositories you want to include

## Installation

Activate the package globally:

```sh
dart pub global activate wario
```

Or run it directly from this repo while developing:

```sh
dart run wario --help
```

## Configuration

By default, Wario reads config from `~/.wario.json` and clones repositories into `~/.wario`.

The config supports exactly one source of repositories:

- `repos`: an explicit list of `owner/name` repositories
- `org` with `filter`: a GitHub organization plus GitHub repository search qualifiers

### Explicit repo list

```json
{
  "cloneDir": "~/.wario",
  "repos": [
    "dart-lang/sdk",
    "google/wireit"
  ]
}
```

### Organization search

```json
{
  "cloneDir": "~/.wario",
  "org": "promptfoo",
  "filter": "archived:false"
}
```

### Config fields

- `cloneDir`: optional destination directory for managed clones. Defaults to `~/.wario`.
- `repos`: optional explicit repo list.
- `org`: optional GitHub organization to search.
- `filter`: optional GitHub repository search filter string appended to `org:<org>`.

Rules:

- You must define either `repos` or `org`.
- You cannot define both `repos` and `org` in the same config.
- Legacy repo objects like `{"repo":"owner/name","language":"dart"}` are still accepted, but `language` is ignored.

### Filter syntax

The `filter` value follows GitHub repository search syntax. Common examples:

- `archived:false`
- `archived:false is:public`
- `archived:false topic:cli`
- `archived:false fork:false`

Wario builds the final query as:

```text
org:<org> <filter>
```

For the default config on this machine, that means:

```text
org:promptfoo archived:false
```

## Authentication

For org-based searches, Wario can only see repositories that GitHub allows the current identity to search.

Token lookup happens in this order:

1. `WARIO_GH_TOKEN`
2. `GH_TOKEN`
3. `GITHUB_TOKEN`
4. `gh auth token`

If none of those are available, Wario warns and GitHub search results may only include public repositories.

To verify your GitHub CLI login:

```sh
gh auth status
```

## Commands

### `wario sync`

Clone any missing repositories and update repositories that are already present in the clone root.

```sh
wario sync
```

Use a non-default config file:

```sh
wario --config ~/work/my-wario.json sync
```

Behavior:

- If the config file does not exist, Wario stops with a friendly error.
- Missing repos are cloned over HTTPS.
- Existing repos are updated with `git pull --ff-only`.
- Org searches are resolved before cloning begins.

### `wario exec`

Run a command in every immediate child directory of the clone root.

```sh
wario exec -- git status --short
```

By default, Wario executes commands with a concurrency of `5`.

```sh
wario exec --concurrency 5 -- git fetch --all
wario exec --concurrency 10 -- git status --short
```

Behavior:

- Concurrency must be at least `1`.
- Only immediate subdirectories of the clone root are targeted.
- Stdout and stderr from child commands are streamed back to the terminal.
- If the clone root does not exist yet, Wario tells you to run `wario sync` first.

## Example Setup

Create the default config:

```json
{
  "cloneDir": "~/.wario",
  "org": "promptfoo",
  "filter": "archived:false"
}
```

Then sync and run a command across the repos:

```sh
wario sync
wario exec -- git status --short
```

## Development

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

Run quality checks:

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

See [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml).

## Project Layout

- `bin/wario.dart`: CLI entrypoint and argument parsing
- `lib/config.dart`: config loading and validation
- `lib/sync.dart`: repo sync behavior
- `lib/exec.dart`: multi-repo command execution
- `lib/utils.dart`: GitHub repo discovery and auth lookup
- `test/`: CLI, config, sync, exec, and auth coverage

## License

[Apache 2.0](LICENSE)
