# Changes from TAN-2020 to development branch

The following changes have been made since version 2020. See the git log of the dev branch for a more comprehensive account of all changes.

## General

### Class 2
* Fix: adjustment reference systems are converted into the target source file's preferred @n system before application.
* Class-1 sources now fetch all @n aliases, so that the host class 2 file can use synonyms. The concept here is that a class 2 file is a kind of extension of a class 1 file, which means that the former should be able to access the terminology of the latter.

#### Adjustments
* Permitted reassignments to be given priority values, so they can be placed in a target div in a requested order.
* Allowed nonvalidation routine to preserve a record in a source div of any passages moved out due to reassign. Marker is made via `<reassigned>`.
* Streamlined allocation of reassigned tokens
* Ranges can be declared of predictable compound numbers, e.g., 4a-4e (or its equivalent, 4a-e).
* Allowed adjustment actions to be interleaved

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
* `tan:filename-satisfies-regex(es)()` and `tan:satisfies-regex(es)()`: 2, 3, 4-param versions to check whether a string matches a given regex and does not match one. Useful for applications that need to filter values based on both matching and non-matching values. 
* `tan:map-put()`: 2-, 3-param versions of a function that inserts or replaces one or more map entries deep within a map. Useful for developming modules of maps for `fn:transform()`.
* `tan:reverse-string()`. Returns a string but in reverse order. 
* `tan:numbers-to-portions()`. Returns a sequence of doubles from 0 through 1 specifying where each input number stands in proportion to the sum of the whole sequence of input numbers. Used for proportionately distributing text that needs to be split. 
* `tan:segment-string()`. Takes a string and a series of decimals between 0 and 1, and a regular expression. Returns the string in segments split at each of the input decimal locaiions, allowing splits only where the regular expression allows. 
 
Altered:
* `tan:text-join()` now has an option to insert a new line at each `<div>` (useful for string differences).

## Languages

Introduced batch replacement for Latin, Greek, Syriac.

## Applications

major tests, refinement to compare class 1 file tool, display of merged sources

## Pending changes

* Consolidate `rename` and `reassign` into a single adjustment action: `move`. With that change, the priority for adjustments will be: skip, equate, move whole divs, move passages. Convert the current two-step process into a single step.