# Changes from TAN-2020 to development branch

The following changes have been made since version 2020. See the git log of the dev branch for a more comprehensive account of all changes.

## General

[items pending]

## Functions

Added: 
* `tan:stamp-tree-with-text-data()`, which efficiently inserts` @_pos` and `@_len` in elements to mark their string position and length. A related `tan:stamp-diff-with-text-data()` handles the process specifically for output from `tan:diff()`; same, mutatis mutandis, for `tan:stamp-collation-with-text-data()`. The process is an important alternative to `tan:analyze-leaf-div-string-length()`, to make it more general purpose. The attribute names seem better than `@string-pos` and `@string-length`. `tan:stamp-diff-with-text-data()` brings with it a template mode `filter-elements`, which fetches only those elements that match or do not match regular expressions passed through tunnel parameters.
* `tan:consolidate-identical-adjacent-divs()` to handle postprocessing the output of `tan:sequence-to-tree()`.
* `tan:greek-graves-to-acutes`. Changes Greek letters with grave accents to their counterparts with acutes.
* `tan:syriac-marks-to-mod-end()`. Shifts combining marks to the end of a word, and puts them in codepoint order, so that more relaxed string comparison can be performed.
* `tan:infuse-diff-and-collate-stats()`. Adds statistics to head of output of tan:diff() and tan:collate().
* `tan:diff-a-map()`. Converts the output of tan:diff() into a `map(xs:integer, item()*)`, where the keys are integers pointing to the position of an a, mapped to its corresponding b content. This function is an important dependency of the compare application, so that texts can be normalized before the comparison is made, then reverted to their original forms. 
* `tan:replace-diff()`. Changes the output of tan:diff() to match the original a and b strings.
* `tan:replace-collation()`. Changes the output of tan:collate() to match an original string of one's choice.
* `tan:normalize-tan-tei-divs()`. Changes TAN-TEI leaf divs so that their contents are space-normalized according to TAN rules.
* `tan:replace-expanded-class-1-body()`. Replaces the text content of an expanded file with another string. It is presumed that the replacement string is similar to the current text content, so `tan:diff()` is used to allocate the replacement.
* `tan:concat-and-sort-diff-output()`. Takes one or more outputs of `tan:diff()`, puts them together, and makes sure that the content follows the sequence a, b, common, with adjacent elements combined.

Altered:
* `tan:text-join()` now has an option to insert a new line at each `<div>` (useful for string differences).

## Languages

Introduced batch replacement for Latin, Greek, Syriac.

## Applications

major tests, refinement to compare class 1 file tool, display of merged sources