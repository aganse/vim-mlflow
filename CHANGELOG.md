# Changelog

## [1.1.2] - 2026-08-31

### Fixed

- Fixed artifact listing to work with S3 and remote stores
- Fixed artifact download to work with S3 and remote stores
- Cleaned up unused imports and a flake8 workflow failure



## [1.1.0] - 2026-06-20

### Added
- Added a Python session cache for experiments, run summaries, run details,
  metric histories, and artifact trees to avoid re-querying MLflow on every
  redraw.
- Added `g:vim_mlflow_runs_cache_mode` with `selected_expt` and `all_expts`
  modes for controlling run-summary cache scope.
- Added `g:vim_mlflow_plotpane_pct` to control the plot-versus-artifact height
  split when both panes are visible.
- Added `pandas` as an explicit dependency and expanded automated coverage for
  cache behavior, viewer layout, and artifact rendering.
- Added pretty-printed display for valid `.json` artifacts in the scratch
  viewer buffer, with raw-text fallback for invalid JSON.

### Changed
- Refactored the main `__MLflow__` sidebar and `__MLflowRuns__` comparison view
  to render from cached in-memory data instead of repeatedly rebuilding from
  fresh MLflow API calls.
- Changed the viewer layout to a shared opposite-side viewer column with plots
  stacked above artifacts.
- Changed the runs-window undo-layout mapping from `<C-u>` to `u`, with a
  confirmation prompt before clearing all column layout tweaks.
- Made vim-mlflow-managed MLflow, runs, plot, and artifact buffers explicitly
  use `nowrap` and `noswapfile` instead of depending on editor defaults.
- Updated README and Vim help documentation for caching, viewer layout, JSON
  display, and new configuration settings.

### Fixed
- Fixed repeated redraws so section toggles, artifact directory expansion, and
  experiment/run selection preserve the visible scroll position much more
  reliably.
- Fixed artifact buffer identity so similarly named artifacts from different
  runs no longer collide.
- Fixed artifact and plot viewer placement so the main `__MLflow__` buffer stays
  pinned while viewer panes are reused predictably.
- Fixed noisy artifact-open status messages that previously triggered hit-enter
  prompts in Vim.
- Fixed Neovim wrapping issues that broke table and artifact display layouts.
