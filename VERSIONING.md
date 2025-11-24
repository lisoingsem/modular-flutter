# Version Management Guide

This guide explains how to manage versions for the `modular_flutter` package.

## Semantic Versioning

We follow [Semantic Versioning](https://semver.org/) (SemVer):

- **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)
  - **MAJOR**: Breaking changes (incompatible API changes)
  - **MINOR**: New features (backward compatible)
  - **PATCH**: Bug fixes (backward compatible)

## How to Update Version

### 1. Update `pubspec.yaml`

```yaml
version: 0.2.0  # Update this line
```

### 2. Update `CHANGELOG.md`

Add a new section at the top (under `[Unreleased]`):

```markdown
## [0.2.0] - 2024-11-26

### Added
- New feature description

### Changed
- What changed

### Fixed
- Bug fix description

### Removed
- What was removed (if any)
```

### 3. Commit and Tag

```bash
# Commit changes
git add pubspec.yaml CHANGELOG.md
git commit -m "Bump version to 0.2.0"

# Create a git tag
git tag -a v0.2.0 -m "Version 0.2.0"

# Push commits and tags
git push origin master
git push origin v0.2.0
```

## Version Examples

### Patch Release (0.1.0 → 0.1.1)
- Bug fixes
- Documentation updates
- Internal refactoring

```bash
# Update pubspec.yaml
version: 0.1.1
```

### Minor Release (0.1.0 → 0.2.0)
- New features
- New CLI commands
- New APIs (backward compatible)

```bash
# Update pubspec.yaml
version: 0.2.0
```

### Major Release (0.1.0 → 1.0.0)
- Breaking changes
- API changes
- Major refactoring

```bash
# Update pubspec.yaml
version: 1.0.0
```

## Publishing to pub.dev

After updating the version:

```bash
# Check package
dart pub publish --dry-run

# Publish
dart pub login
dart pub publish
```

## Version in Code

The version is automatically available from `pubspec.yaml` when the package is published. Users can check the version:

```bash
# Check installed version
dart pub deps | grep modular_flutter
```

## Best Practices

1. **Always update CHANGELOG.md** when bumping version
2. **Use git tags** for releases (e.g., `v0.2.0`)
3. **Test before publishing** major/minor versions
4. **Follow SemVer** strictly for user trust
5. **Document breaking changes** clearly in CHANGELOG

