# Contributing

Guidelines for contributing to Wellnot.

## Dev Environment Setup

### All platforms

1. Fork the repository and clone it locally
2. Install [asdf](https://asdf-vm.com/) for version management:
   ```bash
   # Linux
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
   echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc  # or ~/.bashrc
   source ~/.zshrc

   # macOS
   brew install asdf
   ```
3. Install project dependencies via asdf (the `.tool-versions` file pins Flutter and Changie versions):
   ```bash
   asdf plugin add flutter
   asdf plugin add changie
   asdf install
   ```
4. Run `flutter pub get` to install dependencies
5. Install [pre-commit](https://pre-commit.com/) and set up the Git hooks:
   ```bash
   pip install pre-commit   # or: brew install pre-commit
   pre-commit install
   ```
6. Run `flutter test` to verify everything works

### Linux (Android development)

Linux supports Android development only — iOS builds are not possible on Linux.

1. Install Android Studio for emulator and SDK management
2. Enable USB debugging on your Android device
3. Verify setup: `flutter doctor` should show Android toolchain as ready

### macOS (Android + iOS development)

macOS supports both Android and iOS development.

**For Android:**
1. Install Android Studio for emulator and SDK management

**For iOS:**
1. Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) from the Mac App Store
2. Install Xcode command-line tools:
   ```bash
   sudo xcode-select --install
   ```
3. Accept the Xcode license:
   ```bash
   sudo xcodebuild -license accept
   ```
4. Install CocoaPods:
   ```bash
   brew install cocoapods
   ```
5. Open the iOS project to configure signing:
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Select the **Runner** target > **Signing & Capabilities**
   - Check **Automatically manage signing**
   - Select your Apple Developer account as the Team
6. Connect an iPhone via USB, trust the computer, then run:
   ```bash
   flutter run
   ```
7. Verify setup: `flutter doctor` should show both Android and Xcode toolchains as ready

### Pre-commit hooks

The project uses [pre-commit](https://pre-commit.com/) to enforce code quality on every commit. After running `pre-commit install`, the following hooks run automatically:

| Hook | What it does |
|------|-------------|
| trailing-whitespace | Trims trailing spaces |
| end-of-file-fixer | Ensures files end with a newline |
| check-merge-conflict | Blocks unresolved conflict markers |
| check-yaml | Validates YAML syntax |
| detect-private-key | Prevents committing private keys |
| dart format | Auto-formats Dart files |
| flutter analyze | Catches lint errors |

To run all hooks manually against every file:

```bash
pre-commit run --all-files
```

## Branching

- Create feature branches from `main` using the naming convention `feature/<feature-name>`
- Bug fix branches use `fix/<description>`
- Keep branches focused on a single change

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use for |
|--------|---------|
| `feat:` | New functionality |
| `fix:` | Bug fixes |
| `docs:` | Documentation only |
| `chore:` | Dependency updates, config changes |
| `test:` | Adding or updating tests |
| `refactor:` | Code changes that don't add features or fix bugs |
| `style:` | Formatting, whitespace |
| `ci:` | CI/CD changes |

Keep commit messages concise and high-level. Focus on *why*, not *what*.

## Pull Requests

- PRs target `main` and require CI to pass (analyze, test, format)
- PR titles must follow conventional commit format (enforced by CI)
- Include a summary of changes and a test plan
- Keep PRs focused; split large changes into smaller PRs when possible

## Changelog

If your PR includes user-facing changes (`feat:`, `fix:`, or `perf:` prefix), include a changelog fragment:

```bash
changie new
```

Follow the prompts to describe your change (kind, description, platform). The fragment file in `.changes/unreleased/` is committed with your PR. CI will fail if a user-facing PR is missing a fragment — add the `skip-changelog` label to bypass if the change is truly not user-facing.

Changie is managed via asdf and pinned in `.tool-versions`. Install it with:

```bash
asdf plugin add changie
asdf install changie
```

## Code Style

### General

- Run `dart format .` before committing
- Run `flutter analyze` and fix all issues before opening a PR
- Follow the lints defined in `analysis_options.yaml` (via `flutter_lints`)

### Dart-specific

- **No ternary operators** — use `if`/`else` blocks for readability
- **No hardcoded size values** in widget code — use named constants from `lib/constants/layout.dart`
- **Use Theme text styles** (`Theme.of(context).textTheme.bodyLarge`, etc.) instead of hardcoded `fontSize` values
- **Use theme-aware colors** instead of hardcoded `Colors.grey.shade200` or similar — prefer `Theme.of(context).colorScheme.*`

### Documentation

- Add file-level comments with a brief purpose description and cross-references to related files
- Add doc comments on all public classes, methods, and non-trivial helpers
- Add inline "why" comments on non-obvious logic — skip comments that just restate the code
- Test files should have file-level doc comments explaining what is being tested

### Architecture

- Follow the existing layer structure: Screens -> Services -> Database
- Screens access the database via `context.read<AppDatabase>()` in `didChangeDependencies()` with an `_initialized` guard
- Keep business logic out of widget `build()` methods — precompute in state or helper methods
- New constants go in `lib/constants/` (not inline in screens)

## AI-Assisted Development

AI tools (Claude Code, GitHub Copilot, etc.) are welcome for contributions. However, AI usage must always be explicitly attributed:

- **Commits:** Include a `Co-Authored-By` trailer for the AI tool used. Example:
  ```
  feat: add date range export filter

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- **Pull requests:** Check the "AI assistance" box in the PR template and note which tool was used
- **Code review:** AI-assisted contributions are reviewed with the same rigor as manual contributions. You are responsible for understanding and testing all AI-generated code.
- **TDD requirement:** AI-assisted contributions must follow TDD - write failing tests first, then implement

## Testing

- All new features should include unit and/or widget tests
- Use `test/helpers/test_database.dart` for in-memory database instances
- Use `SharedPreferences.setMockInitialValues({})` in `setUp` for tests involving SharedPreferences
- Run `flutter test` and ensure all tests pass before opening a PR

### Test conventions

- **Test naming:** All test descriptions must follow a user story format: `'As a user, I expect <outcome> when <action/condition>'`. Add extra context at the end if needed (e.g., `— regression test for severity data-loss bug`)
- Group related tests with `group()`
- Use `pumpAndSettle()` for most screens; use `pump()` for screens with infinite animations (e.g., `TableCalendar`)
- Advance past `Future.delayed` timers with `pump(Duration(...))` when needed

## Database Changes

If you modify any Drift table definitions in `lib/services/database.dart`:

1. Bump `schemaVersion`
2. Add migration logic in the `onUpgrade` callback
3. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `database.g.dart`
4. Never edit `database.g.dart` manually

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** — breaking changes
- **MINOR** — new features (backwards-compatible)
- **PATCH** — bug fixes (backwards-compatible)
