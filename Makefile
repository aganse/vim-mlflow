.PHONY: codestyle-python-flake8 codestyle-vimscript-vint unittests unittests-vim unittests-vim-vim unittests-vim-nvim unittests-python env

env:
	@python3 -m pip install -r requirements.txt

codestyle: codestyle-vimscript-vint codestyle-python-flake8

codestyle-vimscript-vint:
	@command -v vint >/dev/null 2>&1 || { echo "vint not available; install it (pip install vim-vint)."; exit 1; }
	vint plugin

codestyle-python-flake8:
	@python3 -m flake8 python tests/python tests/fixtures

unittests: unittests-vim unittests-python

unittests-vim: unittests-vim-nvim unittests-vim-vim

unittests-vim-vim:
	@echo
	@echo --
	@echo Starting Vim unittest...
	@command -v vim >/dev/null 2>&1 || { echo "vim not available on PATH."; exit 1; }
	@rm -f vim-test.log
	@vim -E -u NONE -i NONE -V1vim-test.log -c "source tests/vim/run_tests.vim" -c "qa" || { cat vim-test.log; exit 1; }
	@rm -f vim-test.log

unittests-vim-nvim:
	@echo
	@echo --
	@echo Starting NVim unittest...
	@command -v nvim >/dev/null 2>&1 || { echo "nvim not available on PATH."; exit 1; }
	@rm -f nvim-test.log
	@nvim --headless -u NONE -i NONE -V1nvim-test.log -c "source tests/vim/run_tests.vim" -c "qa" || { cat nvim-test.log; exit 1; }
	@rm -f nvim-test.log

unittests-python:
	@echo --
	@echo Starting Python unittest...
	@command -v pytest >/dev/null 2>&1 || { echo "pytest not available; install it in your virtualenv."; exit 1; }
	@pytest tests/python
