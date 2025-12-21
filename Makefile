.PHONY: lint test-python test-vim test-vim-vim test-vim-nvim

lint:
	@python3 -m flake8 python tests/python tests/fixtures

test-python:
	@command -v pytest >/dev/null 2>&1 || { echo "pytest not available; install it in your virtualenv."; exit 1; }
	@pytest tests/python

test-vim-vim:
	@command -v vim >/dev/null 2>&1 || { echo "vim not available on PATH."; exit 1; }
	vim -Es -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"

test-vim-nvim:
	@command -v nvim >/dev/null 2>&1 || { echo "nvim not available on PATH."; exit 1; }
	nvim --headless -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"

test-vim: test-vim-vim test-vim-nvim
