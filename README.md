# Pig mode for Emacs

pig-mode is an Emacs major mode for editing [Pig][1]
scripts. Currently it supports syntax highlighting and indentation for
Pig versions 0.2 to 0.11. It also supports a local grunt shell as well
as snippets.  We track the changes to Pig syntax and try to support
new Pig features ASAP.

PS. This project was originally hosted on sourceforge.net; we still
maintain the page there, but from now on all new changes will be
pushed to github first.

[1]: http://hadoop.apache.org/pig

## Installation

### Package Installation

The easiest way is to install the ELPA package from MELPA with `M-x
package-install RET pig-mode`. All dependencies are automatically
installed.

### Manual Installation

To install `pig-mode` manually, clone the repository:

```lisp
git clone https://github.com/motus/pig-mode
```

Put it somewhere `emacs` knows to look for it and in your `.emacs`
file, add this:

```lisp
(require 'pig-mode)
```

## Configuration

Set variables in `.emacs` or with `customize-group RET pig RET`
(this works only after `pig-mode` has been loaded).

```lisp
(setq pig-executable "/path/to/pig-0.11.1/bin/pig")
(setq pig-executable-options '("-x" "local"))
(setq pig-executable-prompt-regexp "^grunt> ")
(setq pig-indent-level 4)
(setq pig-version "0.11.1")
```

Add the following to set up processing snippets for [yasnippet][2]:

```lisp
(autoload 'pig-snippets-initialize "pig-snippets" nil nil nil)
(eval-after-load 'yasnippet '(pig-snippets-initialize))
```

[2]: https://github.com/capitaomorte/yasnippet

## Usage

The default key-bindings are:

    C-c C-z    Run Grunt Shell.
    C-c C-r    Pig Eval Region.
    C-c C-l    Pig Eval Line.
    C-c C-n    Pig Eval line and move to the Next one.
    C-c C-b    Pig Eval Buffer.
    C-c C-p    Pig Eval Paragraph.
    C-c C-f    Attempt to find the doc page for a given keyword.
    C-c C-s    Site-search Apache Pig web for a given query.
