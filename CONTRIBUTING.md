# Contributing

Thank you for your interest in contributing.  Please read this document
carefully before opening an issue or pull request.


## Scope and expectations

This project is a Vim plugin implemented in Vim script with a Python backend.
It is maintained on a best-effort basis by a single maintainer alongside other
commitments.  The primary goals are correctness, stability, and low
maintenance overhead (but some feature expansion and keeping up with version
updates of MLflow/Vim/NVim are still of interest!).

The following contributions are most welcome:

* Bug fixes with clear reproduction steps
* Documentation improvements
* Small, focused enhancements that align with the existing design

The following are less likely to be accepted:

* Large or architectural changes
* Features that significantly increase configuration surface area
* Changes that introduce new heavy dependencies

One goal of this plugin is breadth of support, ie ensuring it works on both
Vim and NVim, on Linux/MacOS/Windows, and on older versions of the supporting
tools.  So contributions are expected to support the minimum versions of:
Vim 8.2, NVim v0.11.5, Python 3.10, and MLflow 2.12.0. (Ok that NVim version
is not old but the rest are - point being to accommodate older versions in
addition to the newer ones.)  Of course MLflow in particular has features in
v3.x that are not available in x2.x, but the point is to enable it to still
work with v2.x within the limits of v2.x's capabilities.

Vim-specific contribution requirements:

* `:help` documentation: User-facing changes must update the appropriate
  `doc/*.txt` help files with proper help tags. README-only documentation is
  not sufficient for end-user behavior.
* Backward compatibility: Behavior changes require clear justification and
  corresponding documentation updates.  Preserving existing workflows is
  strongly preferred.

In addition to unittests and codestyle workflows passing, contributors are
expected to thoroughly test their updates end-to-end themselves within vim/nvim
before submitting a PR.


## Issues

Before opening an issue:

* Check existing issues to avoid duplicates
* For bugs, include Vim/NVim version, Python version, OS version, and minimal
  repro steps
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
* Write commit messages per [commit.style](https://commit.style).

All PRs must pass CI before they will be reviewed. Review may take time, and
not all PRs will be merged.


## Code of conduct

Contributors are expected to be respectful and professional in their
communication and behavior at all times.


## License

By contributing, you agree that your contributions will be licensed under the
project’s license.
