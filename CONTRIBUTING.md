# Contributing

Thank you for your interest in contributing. Please read this document
carefully before opening an issue or pull request.

## Scope and expectations

This project is a Vim plugin implemented in Vim script with a Python backend.
It is maintained on a best-effort basis alongside other commitments.  The
primary goal is correctness, stability, and low maintenance overhead.

The following contributions are most welcome:

* Bug fixes with clear reproduction steps
* Documentation improvements
* Small, focused enhancements that align with the existing design

The following are less likely to be accepted:

* Large or architectural changes
* Features that significantly increase configuration surface area
* Changes that introduce new heavy dependencies

## Issues

Before opening an issue:

* Check existing issues to avoid duplicates
* For bugs, include Vim version, Python version, OS, and minimal repro steps
* For feature requests, clearly describe the use case and why it fits the
  project’s scope

Issues that are vague, unreproducible, or out of scope may be closed without
further discussion.

## Pull requests

Guidelines:

* Keep PRs small and narrowly scoped
* One logical change per PR
* Follow existing code style in both Vim script and Python
* Add or update tests when applicable
* Update documentation if behavior changes

All PRs must pass CI before they will be reviewed. Review may take time, and
not all PRs will be merged.

## Vim-specific contribution rules

The following guidelines apply specifically to this project as a Vim plugin
with a Python backend:
1. Compatibility baseline: Contributions must support the minimum Vim and Python
   versions documented in the README, Vim 8.2 and NVim v0.11.5.
2. `:help` documentation: User-facing changes must update the appropriate
   `doc/*.txt` help files with proper help tags. README-only documentation is not
   sufficient for end-user behavior.
3. Startup and performance: Changes must not introduce noticeable Vim startup
   delays or latency in common interactive paths.  Python code should be
   imported lazily and invoked only when needed.
4. Vimscript hygiene: Avoid global namespace pollution. Prefer `autoload/`
   functions and script-local state. Sourcing plugin files should not cause side
   effects beyond plugin initialization.
5. Python integration: Long-running or blocking Python operations must not
   execute synchronously on the main Vim thread. Errors crossing the Vim/Python
   boundary should be handled defensively.
6. Backward compatibility: Behavior changes require clear justification and
   corresponding documentation updates.  Preserving existing workflows is
   strongly preferred.

## Development setup

Basic expectations:

* Vim with +python or +python3 support
* A supported Python version as specified in the README

Project-specific setup and test instructions are documented in the README.

## Code of conduct

All contributors are expected to follow the project’s Code of Conduct.
Unacceptable behavior will not be tolerated.

## License

By contributing, you agree that your contributions will be licensed under the
project’s license.
