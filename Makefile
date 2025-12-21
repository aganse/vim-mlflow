.PHONY: lint test-python test-vim test-vim-vim test-vim-nvim

flake8:
	@python3 -m flake8 python tests/python tests/fixtures

unittests-python:
	@command -v pytest >/dev/null 2>&1 || { echo "pytest not available; install it in your virtualenv."; exit 1; }
	@pytest tests/python

unittests-vim-vim:
	@command -v vim >/dev/null 2>&1 || { echo "vim not available on PATH."; exit 1; }
	vim -Es -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"
	#vim -E -u NONE -i NONE \
	#  -c "try | source tests/vim/run_tests.vim | catch | messages | echoerr v:exception | cquit 1 | endtry" \
	#  -c "messages" -c "qa"

unittests-vim-nvim:
	@command -v nvim >/dev/null 2>&1 || { echo "nvim not available on PATH."; exit 1; }
	nvim --headless -u NONE -i NONE -c "source tests/vim/run_tests.vim" -c "qa"

unittests-vim: unittests-vim-nvim unittests-vim-vim
