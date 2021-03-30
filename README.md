# Text Alignment Network 

[http://textalign.net](http://textalign.net)

Version 2020 (alpha release), development branch

TAN has submodules, which must be invoked using the `--recurse-submodules` option:
`git clone --recurse-submodules [GIT_SOURCE_PATH]`

New to TAN? Start with directories marked with an asterisk.

* `applications/`: mostly XSLT stylesheets for creating, editing, converting, and using with TAN files. 
* `applications-2/`: XSLT 3.0 upgrade, work in progress.
* \*`examples/`: A small library of example TAN files. Snippets of these examples appear in the guidelines.
* `functions/`: The TAN function library, the core engine for validation and applications.
* `functions-2/`: XSLT 3.0 upgrade, work in progress.
* \* `guidelines/`: the main documentation for TAN. See also http://textalign.net/release/TAN-2018/guidelines/xhtml/index.xhtml.
* `maintenance/`: reserved for TAN development
* `output/`: empty directory for placing sample output
* `parameters/`: Parameters that can be altered, to adjust both validation and activities.
* `parameters-2/`: XSLT 3.0 upgrade, work in progress
* `schemas/`: The principle schemas for validating TAN files.
* `schemas-2/`: XSLT 3.0 upgrade, work in progress
* `templates/`: Templates in various formats, both TAN and non-TAN. Useful for activities.
* `tests/`: reserved for TAN development
* `vocabularies/`:: standard TAN vocabulary files (TAN-voc).

Directories marked `-2` represent a deep revision of TAN to XSLT 3.0 and a more integrated package. Currently they are presented in parallel to their non-numbered counterparts. In future versions of this development branch those `-2` directories will lose the suffix, and become the main files.

If you wish to add the older TAN function library to your XSLT applications, use `<xsl:include href="functions/TAN-A-functions.xsl"/>` and `<xsl:include href="functions/TAN-extra-functions.xsl"/>`.

If you wish to access the XSLT 3.0 upgrade (still in progress), you need only one line: `<xsl:include href="functions-2/TAN-function-library.xsl"/>` 

This is the development branch of a future alpha release of TAN. Many new features and enhancements are planned. Participation in developing TAN is welcome. If you create or maintain a library of TAN files, share it.