# Contributing to BRIDGE v2.1 Toolkit

Thanks for your interest in improving BRIDGE.

## Before You Start

- Search existing issues and pull requests to avoid duplicates.
- For significant changes, open an issue first to align on scope.
- Keep contributions focused and limited to one logical change per pull request.

## Local Development

1. Fork and clone the repository.
2. Make your changes in a feature branch.
3. Rebuild distributable archives when pack files change:

```bash
./package.sh
```

4. Validate setup behavior for any impacted pack:

```bash
./setup.sh --name "Test Project" --pack claude-code -o /tmp
```

## Pull Request Guidelines

- Describe what changed and why.
- Include validation steps and command output when relevant.
- Update documentation when behavior, commands, or workflow changes.
- Avoid unrelated refactors or formatting-only edits.

## Security and Secrets

- Never commit API keys, tokens, credentials, or private data.
- Follow `SECURITY.md` for vulnerability reporting.

By contributing, you agree to follow this repository's `CODE_OF_CONDUCT.md`.
