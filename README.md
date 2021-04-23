# Text Alignment Network 

[http://textalign.net](http://textalign.net)

Version 2020 (alpha release), development branch

TAN has submodules, which must be invoked using the `--recurse-submodules` option:
`git clone --recurse-submodules [GIT_SOURCE_PATH]`

New to TAN? Start with directories marked with an asterisk.

* `applications/`: XSLT stylesheets for creating, editing, converting, and using TAN files.
* \*`examples/`: A small library of example TAN files. Snippets of these examples appear in the guidelines.
* `functions/`: The TAN function library, the core engine for validation and applications.
* \* `guidelines/`: the main documentation for TAN. See also http://textalign.net/release/TAN-2018/guidelines/xhtml/index.xhtml.
* `maintenance/`: reserved for TAN development
* `output/`: empty directory for placing sample output
* `parameters/`: Parameters that can be altered, to adjust both validation and activities.
* `schemas/`: The principle schemas for validating TAN files.
* `templates/`: Templates in various formats, both TAN and non-TAN. Useful for activities.
* `tests/`: reserved for TAN development
* `vocabularies/`:: standard TAN vocabulary files (TAN-voc).

If you wish to include the TAN library in your XSLT project, you need only one line: `<xsl:include href="functions/TAN-function-library.xsl"/>` 

Directories marked `-old` represent the generation of schemas, functions, applications, and parameters that were part and parcel of the XSLT 2.0 versions of TAN, retained for reference.

This is the development branch of a future alpha release of TAN. Many new features and enhancements are planned. Participation in developing TAN is welcome. If you create or maintain a library of TAN files, share it.