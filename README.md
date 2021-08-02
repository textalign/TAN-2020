# Text Alignment Network 

[http://textalign.net](http://textalign.net)

Version 2021 (alpha release), development branch

New to TAN? Start here:

* [home page](http://textalign.net)
* `examples/`: A small library of assorted TAN files.
* `guidelines/`: the main documentation for TAN (see also [XHTML, 2020 verision](http://textalign.net/release/TAN-2020/guidelines/xhtml/index.xhtml)).

Want to do something practical? Start here:

* `applications/`: XSLT applications for doing cutting-edge publishing, research, and analysis with TAN / TEI files.
* `utilities/`: XSLT applications for creating, editing, and converting TAN / TEI files.

Want configure and develop? Start here:

* `functions/`: The TAN function library, the heart of validation, applications, and utilities.
* `maintenance/`: resources for developers, to validate and update core TAN assets.
* `output/`: directory for sample output
* `parameters/`: settings to configure TAN validation, applications, and utilities.
* `schemas/`: validates TAN files.
* `templates/`: blank files in various formats, both TAN and non-TAN, used by the applications and utilities.
* `vocabularies/`: standard TAN vocabulary files (TAN-voc).

If you are developing an XSLT application that could benefit from the TAN library, you need only one line: `<xsl:include href="functions/TAN-function-library.xsl"/>` 

TAN has optional submodules for JavaScript dependencies in the output and maintenance subdirectories. To get these, use:
`git clone --recurse-submodules [GIT_SOURCE_PATH]`

This is the development branch of a future alpha release of TAN. Many new features and enhancements are planned. Participation in developing TAN is welcome. If you create or maintain a library of TAN files, share it.