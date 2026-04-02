# AGENTS

This file gives project-specific guidance to coding agents and contributors working in this repository.

## Purpose

Wario is a Dart CLI for managing many GitHub repositories from a single local workspace.

The current product surface is intentionally small:

- `sync`: discover, clone, and update repositories
- `exec`: run commands across cloned repositories with bounded concurrency

When making changes, prefer preserving that simplicity over adding broad abstractions.

## Tech Stack

- Dart 3
- `package:args` for CLI parsing
- `package:http` for GitHub API calls
- `package:test` for tests

## Current Behavior To Preserve

- Default config path is `~/.wario.json`
- Default clone root is `~/.wario`
- Clone URLs use HTTPS, not SSH
- Config supports either:
  - `repos`
  - `org` plus `filter`
- Missing config for `sync` should produce a friendly error
- Org searches should try auth in this order:
  - `WARIO_GH_TOKEN`
  - `GH_TOKEN`
  - `GITHUB_TOKEN`
  - `gh auth token`
- `exec` defaults to concurrency `5`

## Implementation Notes

- `lib/config.dart` owns config parsing and validation
- `lib/utils.dart` owns GitHub repo discovery and auth token lookup
- `lib/sync.dart` owns clone/update behavior
- `lib/exec.dart` owns command fan-out and concurrency limits
- `bin/wario.dart` should stay thin and mostly coordinate parsing and dispatch

Prefer keeping business logic in `lib/` instead of growing the CLI entrypoint.

## Editing Guidelines

- Keep changes ASCII unless a file already requires something else.
- Prefer small, direct implementations over framework-like abstractions.
- Preserve user-facing stderr/stdout messaging unless you are intentionally improving it.
- Keep clone/update behavior explicit and easy to trace.
- When adding flags, document them in the README and test them through the CLI where practical.

## Testing Expectations

Before wrapping up a change, run:

```sh
dart format --output=none --set-exit-if-changed bin lib test
dart analyze
dart test -r expanded
```

Add or update tests when changing:

- config parsing
- CLI argument behavior
- GitHub auth lookup
- org search query construction
- sync behavior
- exec concurrency behavior

## Common Pitfalls

- Do not close an `http.Client` before awaited async work finishes.
- Be careful with `ArgParser` command parsing and `--` passthrough semantics.
- Org searches may look correct while still being unauthenticated; preserve the auth warning path.
- `exec` should bound concurrency, not launch every repo command at once.

## Documentation

If behavior changes, update both:

- `README.md` for end users
- `AGENTS.md` for future maintainers and coding agents
