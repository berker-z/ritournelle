# Repository Guidelines

## Project Structure & Module Organization
- Root contains `project.godot` (Godot 4.5 mobile profile) and the default `icon.svg`; `.godot/` is editor/import cache and stays untracked per `.gitignore`.
- Avoid committing `/android/` export outputs; keep keystores and signing configs local.
- Add source assets under `assets/`, scenes under `scenes/`, and scripts under `scripts/` (create the folders if missing). Place reusable shaders or materials in `materials/` to keep imports tidy.
- Reference assets with `res://` paths so they remain valid across platforms.

## Build, Test, and Development Commands
- `godot4 --editor project.godot` — open the project with current settings.
- `godot4 --path . --run` — run the configured main scene (set in Project Settings → Run → Main Scene).
- After an export preset exists, `godot4 --path . --export-release android build.apk` — produce an Android package via CLI; presets and keystore paths must be configured in the editor first.
- Store export presets in version control; keep secrets out of the repo and inject them via env vars or local files.

## Coding Style & Naming Conventions
- GDScript defaults: 4-space indent, UTF-8, one class per file. Prefer snake_case for variables/functions/signals and PascalCase for scene files and node classes.
- Name root nodes after purpose (`Main`, `HUD`); suffix UI scenes with `*UI.tscn` for clarity.
- Keep scripts near their scenes; favor `_ready` for setup and limit per-frame work to `_process`/`_physics_process` only when needed.
- Use the Godot editor formatter (`Ctrl+Alt+L`) before committing to normalize spacing and imports.

## Testing Guidelines
- No automated test harness is present; smoke-test interactively via the editor (F5) or `godot4 --path . --run` before pushing.
- Document manual test steps in PR descriptions. For logic-heavy modules, add a Godot unit test plugin (e.g., GUT/WAT) before merging to keep regressions low.

## Commit & Pull Request Guidelines
- History is small; follow Conventional Commits (`feat:`, `fix:`, `chore:`) with short, imperative subjects.
- PRs should include: concise summary, linked issue/task, screenshots or recordings for visual/UI changes, and notes on manual tests performed.
- Keep diffs free of `.godot/` cache, `/android/` exports, and other generated artifacts.
