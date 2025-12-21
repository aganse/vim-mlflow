# Test Suite

This directory contains unit tests for both the Python helper modules and the
Vimscript plugin logic.

## Layout

- `tests/python/`: Pytest-based unit tests that exercise `python/vim_mlflow*.py`.
- `tests/vim/`: Headless Vimscript assertions run through `vim` or `nvim`.
- `tests/fixtures/`: Lightweight helpers that build fake MLflow objects for tests.

## Running Locally

```bash
# Python tests
pytest tests/python

# Vimscript tests (requires vim or nvim)
nvim --headless -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"
# or
vim -Es -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"
```
