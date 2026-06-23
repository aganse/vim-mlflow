# Troubleshooting

- The sidebar now caches MLflow data in the embedded Python session, but the
  first load and explicit `r` refreshes still query MLflow synchronously.
  Performance is best when Vim runs close to the tracking server. On slower
  links, increasing `g:vim_mlflow_timeout` may help; for especially large
  tracking servers, keep `g:vim_mlflow_runs_cache_mode = 'selected_expt'` so
  run summaries are loaded lazily per experiment instead of eagerly across all
  experiments.
- Unicode icons require a font that includes box-drawing characters. Set
  `g:vim_mlflow_icon_useunicode = 0` if glyphs look broken, and note that there
  are config vars to change individual icon characters.
- Text artifacts (`*.txt`, `*.json`, `*.yaml`, `MLmodel`) open directly in the
  plugin. `.json` artifacts are pretty-printed in the scratch viewer when they
  contain valid JSON. Binary artifacts are listed but cannot be opened in the
  plugin.
- If the plugin fails to load in classic Vim, verify that Vim supports Python
  (`vim --version`) and that both `mlflow` and `pandas` are importable in Vim's
  Python environment (`:py3 import mlflow, pandas`). In Neovim, also ensure
  `pynvim` is installed.
- Neovim enables line wrapping by default in many setups, but vim-mlflow now
  sets `nowrap` on its managed buffers. If wrapping still appears in a plugin
  buffer, check for custom autocommands or filetype hooks overriding window-
  local options.
