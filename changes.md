# Changes from TAN-2020 to development branch

The following changes have been made since version 2020. See the git log of the dev branch for a more comprehensive account of all changes.

## General

[items pending]

## Functions

Added `tan:stamp-tree-with-text-data()`, which efficiently inserts` @_pos` and `@_len` in elements to mark their string position and length. A related `tan:stamp-diff-with-text-data()` handles the process specifically for output from `tan:diff()`. The process is an important alternative to `tan:analyze-leaf-div-string-length()`, to make it more general purpose. The attribute names seem better than `@string-pos` and `@string-length`. `tan:stamp-diff-with-text-data()` brings with it a template mode `filter-elements`, which fetches only those elements that match or do not match regular expressions passed through tunnel parameters.

`tan:text-join()` given an option to insert a paragraph at each `<div>` (useful for string differences).

## Applications

major tests, refinement to compare class 1 file tool, display of merged sources