# Repository Guidelines

Contents here for agents should be consistent with those in CONTRIBUTING.md for
humans - please mention any conflicts.


## Project Structure & Module Organization
`plugin/vim-mlflow.vim` contains the Vimscript entrypoint, defaults, window
management, and key mappings. Python helpers live in `python/`
(`vim_mlflow.py`, `vim_mlflow_runs.py`, `vim_mlflow_utils.py`) and handle
MLflow API access plus formatting. Tests are split between `tests/python/` for
pytest coverage, `tests/vim/` for headless Vim/Neovim assertions, and
`tests/fixtures/` for fake MLflow objects. User help and reference docs belong
in `doc/`; update `doc/vim-mlflow.txt` for user-facing behavior changes.

## Documentation guidelines
The top level `README.md` should be in GitHub Markdown flavor and contain:
- at very top badges for unittests passing, code linting passing, license,
  and current code version.
- next a brief one-paragraph summary of the project followed by an animated
  GIF screen capture demonstrating use of key features - this screen capture
  will need to be supplied independently by the developer just before a
  milestone but you can request it when the time is right.
- then sections of:  TL;DR, Installation, Usage, Configuration,
  Troubleshooting, Contributing, Making the animated screen-shot gif, and
  Acknowledgements.
The `doc/vim-mlflow.txt` file is the required vim help file for this project
and should be generally consistent with `README.md` although may have some more
details than `README.md` that are more specific to the Vim session usage.
The `doc/description.txt` and `doc/installdetails.txt` files are used when updating
the zipfile contribution to www.vim.org.  The `doc/description.txt` should be
generally consistent with the `README.md`'s brief one-paragraph summary, TL;DR, 
and Usage sections.  The `doc/installdetails.txt` should be generally consistent
with the `README.md`'s Installation section.

## Build, Test, and Development Commands
- `python3 -m venv .venv` — create a local dev environment if a .venv/ dir does not already exist.
- `source .venv/bin/activate` — enter local dev environment when .venv/ dir already exists.
- `make dev-env` — install development dependencies from `dev-requirements.txt`.
- `make unittests` — run all Vimscript and Python tests.
- `make unittests-python` — run `pytest tests/python` only.
- `make unittests-vim` — run headless tests in both Vim and Neovim.
- `make codestyle` — run both linters.
- `make codestyle-python-flake8` / `make codestyle-vimscript-vint` — lint one language at a time.

## Coding Style & Naming Conventions
Use 4-space indentation (no tab characters) in Python and keep lines within the
Flake8 limit of 100 characters. Follow the repository’s existing naming:
snake_case for Python functions/variables, `g:` for user config globals, and
`s:` for script-local Vimscript state. Prefer small helper functions and
preserve compatibility with both Vim and Neovim. Match the current Vimscript
style, including explicit `endif`/`endfunction` blocks and conservative
scripting patterns.  Python functions and methods should have type hints.
Python functions and classes should have brief docstrings - parameters not
needed but at least a one-line descriptor of what the function or class does
for small ones, and several more lines of the description for larger ones.
Vimscript should have at least a one-line descriptor comment at top of each
vimscript function; for especially large or complex vimscript functions use
several lines for that descriptor comment.

## Testing Guidelines
Add or update tests with every functional change. Put Python tests in
`tests/python/test_*.py`; use fixtures from `tests/fixtures/` when mocking
MLflow entities. For plugin behavior, extend `tests/vim/run_tests.vim`. Run
`make unittests && make codestyle` before opening a PR.

## Commit & Pull Request Guidelines
Prefer short, imperative commit subjects such as `Fix utcfromtimestamp()
deprecation warning` or `Update readme`, where the first word is capitalized
and no period at the end.  Keep commits focused and PRs narrowly scoped.
Include a clear description, reproduction steps for bug fixes, linked issues
when relevant, and documentation/test updates for behavior changes.
User-visible changes should update Vim help and other documentation in
`doc/*.txt`, not just `README.md`.
