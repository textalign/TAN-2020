<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Catalyzing input: a TAN-A file -->
    <!-- Secondary input: the catalyzing input expanded, and its sources merged -->
    <!-- Primary output: an html page or diagnostics -->
    <!-- Secondary (main) output: none -->
    
    <!-- This application is one of the more significant for TAN files, because it allows one to see any number of versions of
    a work in the same reading space, with quotations or annotations. It is useful both in the middle stages of a project, where
    you might need to check on and adjust the alignment of a text in light of its peers, or at the end stages of a project,
    where you might be publishing a parallel edition, or using one in for study or teaching. -->
    
    <!-- Should output be diverted to diagnostics (master default template in this stylesheet)? -->
    <xsl:param name="output-diagnostics-on" as="xs:boolean" static="yes" select="false()"/>
    
    <xsl:include href="../get%20inclusions/diff-and-collate-to-html.xsl"/>
    <xsl:import href="../../parameters/application-diff-parameters.xsl"/>
    <xsl:import href="display%20TAN%20as%20HTML.xsl"/>
    <xsl:import href="../get%20inclusions/html-colors.xsl"/>
    
    <xsl:output method="html" indent="false" use-when="not($output-diagnostics-on)"/>
    <xsl:output method="xml" indent="yes" use-when="$output-diagnostics-on"/>
    
    
    <!-- PARAMETERS -->
    <!-- Other important parameters are to be found at /parameters/application-parameters.xsl. -->

    <!-- THIS STYLESHEET -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:display-merged-sources-as-html'"/>
    <xsl:param name="stylesheet-name" select="'Converter of merged TAN-A sources to HTML'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-07-28">Develop output option using nested HTML divs, to parallel the existing output that uses HTML tables</comment>
            <comment who="kalvesmaki" when="2020-09-23">Integrate diff/collate into cells, on both the global and local level.</comment>
            <comment who="kalvesmaki" when="2020-09-23">Support in the css bar clicking source id labels on and off.</comment>
            <comment who="kalvesmaki" when="2020-09-23">Add labels for divs higher than version wrappers.</comment>
        </to-do>
    </xsl:param>
    
    
    
    
    <xsl:param name="validation-phase" select="'terse'"/>

    <!-- Parameters for input pass 1 -->
    <!-- What regular expression must source ids match (e.g., grc|eng-\d+)? If blank, all sources will be fetched. -->
    <xsl:param name="src-ids-must-match-regex" as="xs:string?"/>
    <!-- What regular expression should be used to exclude sources or aliases? -->
    <xsl:param name="src-ids-must-not-match-regex" as="xs:string?"/>
    <xsl:param name="main-langs-must-match-regex" as="xs:string?"/>
    <xsl:param name="main-langs-must-not-match-regex" as="xs:string?"/>
    <!-- For the following parameters, you may find the process more efficient if you code them at <adjustments> in the class 2 file -->
    <xsl:param name="div-types-must-match-regex" as="xs:string?"/>
    <xsl:param name="div-types-must-not-match-regex" as="xs:string?"/>
    <xsl:param name="level-1-div-ns-must-match-regex" as="xs:string?"
        ><!--^(3|90|112)$--></xsl:param>
    <xsl:param name="level-1-div-ns-must-not-match-regex" as="xs:string?"/>
    <xsl:param name="leaf-div-refs-must-match-regex" as="xs:string?"/>
    <xsl:param name="leaf-div-refs-must-not-match-regex" as="xs:string?"
        ><!--^3 ([1-36-9]|4[01]|5[89])--></xsl:param>
    <xsl:param name="leaf-div-must-have-at-least-how-many-versions" as="xs:integer?" select="()"/>

    <xsl:param name="suppress-display-of-adjustment-actions" select="false()"/>
    <!-- Do you wish to convert leaf-div TEI items to plain text? If false, the display will be populated with TEI elements, but this may hamper browser-based text searches, which cannot search across element boundaries. -->
    <xsl:param name="tei-should-be-plain-text" as="xs:boolean" select="false()"/>
    <!-- What replacement character should mark a TEI <app> that has no lemma? -->
    <xsl:param name="marker-for-tei-app-without-lem" as="xs:string?">+</xsl:param>
    <!-- What replacement character should mark a TEI <note>? -->
    <xsl:param name="tei-note-signal-default" as="xs:string?">n</xsl:param>
    <!-- What replacement character should mark a TEI <add>? -->
    <xsl:param name="tei-add-signal-default" as="xs:string?">+</xsl:param>

    <!-- Parameters for input pass 3 (i.e., after merging) -->
    <xsl:param name="levels-to-convert-to-aaa" as="xs:integer*" select="()"/>
    <xsl:param name="suppress-refs" as="xs:boolean?" select="true()"/>
    <xsl:param name="add-display-n" as="xs:boolean" select="true()"/>
    <xsl:param name="fill-defective-merges" select="true()"/>
    <xsl:param name="version-wrapper-class-name" select="'version-wrapper'"/>
    
    <!-- The following parameter is very important, allowing you to pick one or more alias @xml:id/@id that should lead to the master source 
        list. Each alias id will be resolved into constituent versions grouped and sorted in a tree, with sources nested according to alias 
        group. The default looks at the top <alias> and takes the tokenized @idref values as the starting points. -->
    <!-- What sequence of alias idrefs should be used to group and sort sources? -->
    <xsl:param name="sort-and-group-by-what-alias-idrefs" as="xs:string*" select="tokenize(/*/tan:head/tan:vocabulary-key/tan:alias[1]/@idrefs, '\s+')"/>
    <!-- If, when grouping and sorting by aliases, every source encountered be treated as belonging to the primary work, regardless of its declaration? This is useful for including things like commentaries, which may follow the reference system but be defined as a different work. -->
    <xsl:param name="let-alias-groups-equate-works" as="xs:boolean" select="true()"/>

    <!-- Differences: tan:diff() and tan:collate(). By turning it on, you can collapse into 
        a single cell a leaf group of witnesses (grouped by alias). This is a very powerful 
        extra feature for comparative reading, because it lets you see in a more compact 
        reading environment exactly where versions differ from each other. But if you do
        a text search in the browser, you will not find any text that crosses html element
        boundaries, thereby eliminating one of the more important utilities of browser-based
        research. So if you prioritize text searches over reading, do not use the diff/collate
        feature. In fact, you probably also want to turn off TEI element rendering, because many
        leafmost TEI elements split text that you want to have rejoined. 
    -->
    <!-- At what level of similarity should a group of versions in a div be rendered as a difference or collation? Anything other than a number between 0 and 1 will be ignored. If the aggregate difference of a group of versions is less than the decimal provided, no diff/collate will be substituted. -->
    <xsl:param name="render-as-diff-threshhold" as="xs:decimal?" select="0.6"/>
    <!-- What text differences should be ignored when compiling difference statistics? These are built into a series of elements that group <c>s, e.g. <alias><c>'</c><c>"</c></alias> would, for statistical purposes, ignore differences merely of a single apostrophe and quotation mark. This affects only statistics. The difference would still be visible in the diff/collation. -->
    <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
    <!-- Should diffs be rendered word-for-word (true) or character-for-character? -->
    <xsl:param name="snap-to-word" as="xs:boolean" select="true()"/>
    <!-- Is a diff or collation, is the first version of the greatest interest? If false, then the last version will be styled by the CSS as the focus. -->
    <xsl:param name="first-version-is-of-primary-interest" as="xs:boolean" select="true()"/>
    <!-- Should Venn diagrams be inserted for collations of 3 or more versions? If true, processing will take longer, and the HTML file will be larger. -->
    <xsl:param name="include-venns" as="xs:boolean" select="false()"/>
    
    
    
    <!-- START OF THE PROCESS -->

    <!-- Put the TAN-A sources into groups by work. Currently only the first work group will be processed. We do not use TAN-A/head/vocabulary-key/work 
    because the latter is build upon a generous view of allowing aliases to determine several different works in one fell swoop, but that might be
    more than the current user wants, namely, choosing to group works according to selective alias(es). -->
    <xsl:variable name="valid-src-work-vocab" as="element()*">
        <xsl:for-each select="$sources-resolved/*">
            <xsl:sort select="index-of($src-ids, @src)"/>
            <xsl:variable name="this-src-id" select="@src"/>
            <xsl:variable name="this-work" select="tan:head/tan:work" as="element()?"/>
            <xsl:variable name="this-work-vocab" select="tan:element-vocabulary($this-work)"/>
            <work xmlns="tag:textalign.net,2015:ns">
                <xsl:copy-of select="$this-src-id"/>
                <xsl:copy-of select="$this-work-vocab/(tan:item, tan:work)/*"/>
            </work>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="valid-srcs-by-work" select="tan:group-elements-by-IRI($valid-src-work-vocab)"/>
    
    <!-- We accept as valid source ids for the primary merge only candidates from the first work group. -->
    <xsl:variable name="valid-first-work-src-ids"
        select="$valid-srcs-by-work[1]/*/@src[tan:filename-satisfies-regexes(., $src-ids-must-match-regex, $src-ids-must-not-match-regex)]"/>
    
    <!-- First, go through any <alias>es and build a grouping pattern for the chosen work. -->
    <xsl:variable name="alias-based-group-and-sort-pattern" as="element()">
        <source-pattern xmlns="tag:textalign.net,2015:ns">
            <xsl:apply-templates select="$head/tan:vocabulary-key"
                mode="build-source-group-and-sort-pattern">
                <xsl:with-param name="idrefs-to-process" select="$sort-and-group-by-what-alias-idrefs"/>
            </xsl:apply-templates>
        </source-pattern>
    </xsl:variable>

    <!-- Now add the alias-based grouping pattern to any sources for the chosen work that already aren't
    covered by alias groups. -->
    <xsl:variable name="source-group-and-sort-pattern" as="element()">
        <!-- This variable creates a master pattern that will be used to group and sort table columns -->
        <source-pattern xmlns="tag:textalign.net,2015:ns">
            <xsl:apply-templates select="$alias-based-group-and-sort-pattern/*"
                mode="build-source-group-and-sort-pattern"/>
            <xsl:for-each
                select="$valid-first-work-src-ids[not(. = $alias-based-group-and-sort-pattern//tan:idref)]">
                <xsl:variable name="this-pos" select="position()"/>
                <idref>
                    <xsl:if test="$imprint-color-css">
                        <xsl:variable name="this-color-position"
                            select="((count($alias-based-group-and-sort-pattern/*) + $this-pos) mod $primary-color-array-size) + 1"
                        />
                        <xsl:variable name="this-color" select="array:get($primary-color-array, $this-color-position)"/>
                        <xsl:attribute name="color"
                            select="
                                'rgba(' || string-join((for $i in $this-color
                                return
                                    format-number($i, '0.0')), ', ') || ')'"
                        />
                    </xsl:if>
                    <xsl:value-of select="."/>
                </idref>
            </xsl:for-each>
        </source-pattern>
    </xsl:variable>

    <xsl:variable name="alias-names" select="$source-group-and-sort-pattern//tan:alias"/>
    <xsl:variable name="src-id-sequence" select="$source-group-and-sort-pattern//tan:idref"/>

    <xsl:template match="tan:vocabulary-key" mode="build-source-group-and-sort-pattern">
        <!-- This template turns the <alias>es in a <vocabulary-key> into a structured hierarchy consisting of <group> + <alias> and <idref> -->
        <xsl:param name="idrefs-to-process" as="xs:string*"/>
        <xsl:param name="idrefs-already-processed" as="xs:string*"/>
        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="these-aliases" select="tan:alias"/>
        <xsl:for-each select="$idrefs-to-process">
            <xsl:variable name="this-idref" select="."/>
            <xsl:variable name="next-alias" select="$these-aliases[(@xml:id, @id) = $this-idref][1]"/>
            <xsl:variable name="next-idrefs"
                select="tokenize(normalize-space($next-alias/@idrefs), ' ')"/>
            <xsl:choose>
                <xsl:when test="not(exists($next-alias)) and 
                    ($this-idref = $valid-first-work-src-ids or $let-alias-groups-equate-works)">
                    <idref xmlns="tag:textalign.net,2015:ns">
                        <xsl:value-of select="."/>
                    </idref>
                </xsl:when>
                <xsl:when test="not(exists($next-alias))"/>
                <xsl:when test="exists($next-idrefs)">
                    <group xmlns="tag:textalign.net,2015:ns">
                        <alias>
                            <xsl:value-of select="$this-idref"/>
                        </alias>
                        <xsl:apply-templates select="$this-element" mode="#current">
                            <xsl:with-param name="idrefs-to-process" select="$next-idrefs"/>
                            <xsl:with-param name="idrefs-already-processed"
                                select="$idrefs-already-processed, $this-idref"/>
                        </xsl:apply-templates>
                    </group>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    <!-- Deeply skip groups that have no valid idrefs -->
    <xsl:template match="tan:group[not($let-alias-groups-equate-works) 
        and not(descendant::tan:idref[. = $valid-first-work-src-ids])]"
        priority="1"
        mode="build-source-group-and-sort-pattern"/>
    <!-- Add a standard alias id, and perhaps color value, to assist later processing -->
    <xsl:template match="tan:group[tan:alias] | tan:idref" mode="build-source-group-and-sort-pattern">
        <xsl:param name="inherited-color" as="xs:double*"/>
        <xsl:variable name="this-pos" select="count(preceding-sibling::*[not(self::tan:alias)]) + 1"/>
        <xsl:variable name="this-color-array" as="array(*)">
            <xsl:choose>
                <xsl:when test="self::tan:idref and exists($inherited-color)">
                    <xsl:sequence select="$terminal-color-array"/>
                </xsl:when>
                <xsl:when test="exists($inherited-color)">
                    <xsl:sequence select="$secondary-color-array"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$primary-color-array"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="this-color-position"
            select="$this-pos mod array:size($this-color-array) + 1"/>
        <xsl:variable name="this-color" select="array:get($this-color-array, $this-color-position)"
        />
        <xsl:variable name="new-color"
            select="
                if (exists($inherited-color)) then
                    tan:blend-colors($inherited-color, $this-color, $color-blend-midpoint)
                else
                    $this-color"
        />
        <xsl:variable name="group-pos-values"
            as="xs:string+"
            select="
                for $i in ancestor-or-self::tan:group
                return
                    string(count($i/preceding-sibling::*[not(self::tan:alias)]) + 1)"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="self::tan:group">
                <xsl:attribute name="alias-id"
                    select="concat('alias--', string-join($group-pos-values, '--'))"/>
            </xsl:if>
            <xsl:if test="$imprint-color-css">
                <xsl:attribute name="color"
                    select="
                        'rgba(' || string-join((for $i in $new-color
                        return
                            format-number($i, '0.0')), ', ') || ')'"
                />
            </xsl:if>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="inherited-color" select="$new-color"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    

    <!-- Parameters for input pass 4 -->
    <!-- Changes in the second pass of tan:tan-to-html() -->
    
    <!-- Should a bibliography be added? -->
    <xsl:param name="add-bibliography" as="xs:boolean" select="false()"/>
    <!-- Shall the controller label be added? -->
    <xsl:param name="add-controller-label" as="xs:boolean" select="true()"/>
    <!-- Should controller options be added? -->
    <xsl:param name="add-controller-options" as="xs:boolean" select="true()"/>
    <xsl:param name="tables-via-css" as="xs:boolean" select="false()"/>
    <!-- If aligning leaf divs through tables, should the table layout be fixed? -->
    <xsl:param name="table-layout-fixed" as="xs:boolean" select="false()"/>
    <xsl:param name="calculate-width-at-td-or-leaf-div-level" select="false()"/>

    <!-- Post-infusion changes -->
    <xsl:param name="td-widths-proportionate-to-td-count" as="xs:boolean" select="false()"/>
    <xsl:param name="td-widths-proportionate-to-string-length" as="xs:boolean" select="false()"/>
    
    <xsl:param name="imprint-color-css" as="xs:boolean" select="true()"/>
    <!-- Because colors are determined via mod against the size of the array, and because arrays cannot take the zero string,
    the first color will be the second. -->
    <xsl:param name="primary-color-array" as="array(xs:integer+)"
        select="[$ryb-red, $ryb-red-orange, $ryb-orange, $ryb-yellow-orange, $ryb-yellow, $ryb-yellow-green, $ryb-green, $ryb-blue-green, $ryb-blue, $ryb-blue-purple, $ryb-purple, $ryb-red-purple]"/>
    <xsl:param name="secondary-color-array" as="array(xs:integer+)"
        select="[$ryb-yellow-green, $ryb-green, $ryb-blue-green, $ryb-blue, $ryb-blue-purple, $ryb-purple, $ryb-red-purple, $ryb-red, $ryb-red-orange, $ryb-orange, $ryb-yellow-orange, $ryb-yellow]"/>
    <xsl:param name="terminal-color-array" as="array(xs:double+)"
        select="[$white-mask-a70, $white-mask-a60, $white-mask-a50, $white-mask-a40, $white-mask-a30, $white-mask-a20, $white-mask-a10]"
    />
    <xsl:variable name="primary-color-array-size" select="array:size($primary-color-array)"/>
    <xsl:variable name="color-blend-midpoint" select="0.4"/>


    <!-- PASS 1 -->
    <!-- This pass is devoted to anything that needs to be dealt with before merging: filtering out 
        content; dealing with TEI; making the sources look like the original. If you have to filter stuff
        out you might want to consider using <adjustments> in the class 2 file.
    -->

    <xsl:template match="processing-instruction()" mode="input-pass-1"/>
    <xsl:template match="/" mode="input-pass-1">
        <xsl:variable name="this-src-id" select="*/@src"/>
        <xsl:variable name="this-lang" select="*/tan:body/@xml:lang"/>
        <xsl:variable name="src-is-ok" select="$this-src-id = $source-group-and-sort-pattern//tan:idref"/>
        <xsl:variable name="lang-is-ok"
            select="tan:satisfies-regexes($this-lang, $main-langs-must-match-regex, $main-langs-must-not-match-regex)"/>
        <xsl:variable name="this-class" select="tan:class-number(.)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'src id: ', $this-src-id"/>
            <xsl:message select="'lang: ', $this-lang"/>
            <xsl:message select="'src is ok: ', $src-is-ok"/>
            <xsl:message select="'lang is ok: ', $lang-is-ok"/>
        </xsl:if>
        
        <xsl:if test="$src-is-ok and $lang-is-ok and ($this-class = 1)">
            <xsl:document>
                <xsl:apply-templates mode="#current"/>
            </xsl:document>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:source[not(*)]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of
                select="tan:element-vocabulary(.)/tan:item/(tan:IRI, tan:name[not(@norm)], tan:desc)"
            />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:name[@norm]" mode="input-pass-1"/>
    <xsl:template match="tan:vocabulary" mode="input-pass-1">
        <xsl:comment><xsl:value-of select="concat(name(.), ' has been truncated')"/></xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <xsl:copy-of select="tan:shallow-copy(.)"/>
    </xsl:template>
    <xsl:template match="tan:skip | tan:rename | tan:equate | tan:reassign" mode="input-pass-1">
        <xsl:if test="not($suppress-display-of-adjustment-actions = true())">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:body/tan:div" mode="input-pass-1">
        <xsl:variable name="diagnostics" select="false()"/>
        <xsl:variable name="these-ns" select="tan:n"/>
        <xsl:variable name="these-div-types"
            select="tan:type, tokenize(normalize-space(@type), ' ')"/>
        <xsl:variable name="ns-are-ok"
            select="
                some $i in $these-ns
                    satisfies tan:satisfies-regexes($i, $level-1-div-ns-must-match-regex, $level-1-div-ns-must-not-match-regex)"/>
        <xsl:variable name="div-types-are-ok"
            select="
                (some $i in $these-div-types
                    satisfies tan:satisfies-regexes($i, $div-types-must-match-regex, ()))
                and
                (every $j in $these-div-types
                    satisfies tan:satisfies-regexes($j, (), $div-types-must-not-match-regex))"/>
        <xsl:if test="$diagnostics">
            <xsl:message select="'ns: ', $these-ns"/>
            <xsl:message select="'div types: ', $these-div-types"/>
            <xsl:message select="'some @n is ok: ', $ns-are-ok"/>
            <xsl:message select="'some @type is ok: ', $div-types-are-ok"/>
        </xsl:if>
        <xsl:if test="$ns-are-ok and $div-types-are-ok">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:div" mode="input-pass-1">
        <xsl:variable name="these-div-types"
            select="tan:type, tokenize(normalize-space(@type), ' ')"/>
        <xsl:variable name="div-types-are-ok"
            select="
                (some $i in $these-div-types
                    satisfies tan:satisfies-regexes($i, $div-types-must-match-regex, ()))
                and
                (every $j in $these-div-types
                    satisfies tan:satisfies-regexes($j, (), $div-types-must-not-match-regex))"/>
        <xsl:variable name="is-leaf" select="not(exists(tan:div))"/>
        <xsl:variable name="these-refs" select="tan:ref/text()"/>
        <xsl:variable name="refs-are-ok"
            select="
                if ($is-leaf) then
                    (some $i in $these-refs
                        satisfies tan:satisfies-regexes($i, $leaf-div-refs-must-match-regex, ())
                        and
                        (every $j in $these-refs
                            satisfies tan:satisfies-regexes($j, (), $leaf-div-refs-must-not-match-regex)))
                else
                    true()"/>
        <xsl:if test="$div-types-are-ok and $refs-are-ok">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:*" mode="input-pass-1">
        <xsl:if test="not($tei-should-be-plain-text)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:div[tei:*]/text()" mode="input-pass-1">
        <xsl:if test="$tei-should-be-plain-text">
            <xsl:value-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:app[not(tei:lem)]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <lem xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:value-of select="$marker-for-tei-app-without-lem"/>
            </lem>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:note | tei:add" mode="input-pass-1">
        <wrapper xmlns="http://www.tei-c.org/ns/1.0">
            <signal>
                <xsl:choose>
                    <xsl:when test="name(.) = 'add'">
                        <xsl:value-of select="$tei-add-signal-default"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$tei-note-signal-default"/>
                    </xsl:otherwise>
                </xsl:choose>
            </signal>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </wrapper>
    </xsl:template>



    <!-- PASS 1b: eliminate any divs whose leaf divs have been eliminated -->
    <xsl:variable name="input-pass-1b" as="document-node()*">
        <xsl:apply-templates select="$input-pass-1" mode="delete-divs-without-leaf-divs"/>
    </xsl:variable>
    <xsl:template match="tan:div | tan:body" mode="delete-divs-without-leaf-divs">
        <xsl:variable name="divs-from-here-down" select="descendant-or-self::tan:div"/>
        <xsl:variable name="tei-marker" select="descendant::tei:*"/>
        <xsl:variable name="text-marker" select="matches(., '\S')"/>
        <xsl:variable name="is-or-has-leaf-div" select="exists($tei-marker) or exists($text-marker)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'processing: ', tan:shallow-copy(.)"/>
            <xsl:message select="'is or has leaf div: ', $is-or-has-leaf-div"/>
            <xsl:message select="'tei marker: ', $tei-marker"/>
            <xsl:message select="'text marker: ', $text-marker"/>
        </xsl:if>
        
        <xsl:if test="$is-or-has-leaf-div">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    
    

    <!-- PASS 2: Merge the sources -->

    <xsl:param name="input-pass-2" select="tan:merge-expanded-docs($input-pass-1b)"/>
    
    
    

    <!-- PASS 3 -->
    <!-- This pass is devoted to adjusting the merge before the migration to HTML elements. The most
        important part is getting aligned sources into the correct order, and creating the appropriate group 
        labels. -->
    <!-- The heads are constructed hierarchically, because they will form the control that allows the 
        user to hide/show or re-sort sources or groups of sources. But the leafmost texts (versions) in the 
        body are rearranged like a table row (even if we're using <div>s, not <tr>s). We do not want them 
        in a hierarchy. If a user chooses to hide a source, we do not want to see if there are no more 
        shown blocks in a group before deciding whether to turn off the whole group. 
    -->

    <xsl:template match="tan:TAN-T_merge" mode="input-pass-3">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- control mechanism -->
            <div class="control">
                <xsl:apply-templates select="$source-group-and-sort-pattern"
                    mode="regroup-and-re-sort-heads">
                    <xsl:with-param name="items-to-group-and-sort" tunnel="yes" select="tan:head"/>
                </xsl:apply-templates>
            </div>
            <xsl:apply-templates select="tan:body" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:div[tan:div[@type = '#version']]" mode="input-pass-3">
        <!-- This template finds a parent of a version, then groups and re-sorts the descendant versions 
            according to the master $source-group-and-sort-pattern -->
        <!-- Such a version wrapper will wind up being table-like or table-row-like, whether that is executed as 
            an html <table> or through CSS. That decision cannot be made at this point. -->
        <!-- This element wraps one or more versions, which are sorted and grouped in the predefined order. -->
        <!-- In addition, descendant class-2 anchors are pulled up and moved to the end. -->
        <xsl:variable name="children-divs" select="tan:div"/>
        <xsl:variable name="sources-to-process" select="distinct-values(tan:src)"/>
        <xsl:variable name="skip-this-div"
            select="
                exists($leaf-div-must-have-at-least-how-many-versions)
                and (count($sources-to-process) lt $leaf-div-must-have-at-least-how-many-versions)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'This div: ', tan:shallow-copy(.)"/>
            <xsl:message select="'Sources to process: ', $sources-to-process"/>
            <xsl:message select="'Div should be skipped: ', $skip-this-div"/>
        </xsl:if>
        
        <xsl:if test="not($skip-this-div)">
            <xsl:variable name="ns-that-are-integers" select="tan:n[. castable as xs:integer]"/>
            <xsl:variable name="ns-that-are-strings" select="tan:n except $ns-that-are-integers"/>
            <xsl:variable name="distinct-integer-ns" as="element()*">
                <xsl:for-each-group select="$ns-that-are-integers" group-by=".">
                    <xsl:copy-of select="current-group()[1]"/>
                </xsl:for-each-group>
            </xsl:variable>
            <xsl:variable name="distinct-string-ns" as="element()*">
                <xsl:for-each-group select="$ns-that-are-strings" group-by=".">
                    <xsl:copy-of select="current-group()[1]"/>
                </xsl:for-each-group>
            </xsl:variable>
            <!--<xsl:variable name="distinct-string-ns" select="tan:distinct-items($ns-that-are-strings)"/>-->
            <xsl:variable name="rebuilt-integer-sequence"
                select="tan:integers-to-sequence($distinct-integer-ns)"/>
            <xsl:variable name="n-pattern" as="element()+">
                <!-- The idea is that a <div> or a cluster of <div>s might attract many values of @n. They will be either
                calculable as integers or not. Those that are should be treated as distinct ns. Those that are not should be
                treated as synonyms for the same <div> or cluster of <div>s. Those string-based synonyms should be
                associated with the first integer value (if any) as the primary group of <n>s. -->
                <primary-ns xmlns="tag:textalign.net,2015:ns">
                    <xsl:copy-of select="$distinct-string-ns"/>
                    <xsl:copy-of select="$distinct-integer-ns[1]"/>
                </primary-ns>
                <xsl:copy-of select="$distinct-integer-ns[position() gt 1]"/>
            </xsl:variable>
            <xsl:variable name="pre-div-elements-except-n" select="* except (tan:n, tan:div)"/>
            <xsl:variable name="class-2-ref-anchors" select="$children-divs/tan:ref[@q][not(text())]"/>
            <xsl:variable name="class-2-ref-anchors-to-move-here" as="element()*">
                <!-- We do not worry at this point whether the anchor pertains to a work in general or only a specific source. That gets handled later. -->
                <xsl:for-each-group select="$class-2-ref-anchors" group-by="@q">
                    <xsl:sequence select="current-group()[1]"/>
                </xsl:for-each-group> 
            </xsl:variable>
            
            <xsl:if test="$diagnostics-on">
                <xsl:message select="'n pattern: ', $n-pattern"/>
            </xsl:if>
            
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="class" select="$version-wrapper-class-name"/>
                <!-- We eliminate duplication of elements -->
                <xsl:for-each-group select="$pre-div-elements-except-n" group-by="name(.)">
                    <xsl:for-each-group select="current-group()" group-by=".">
                        <xsl:copy-of select="current-group()[1]"/>
                    </xsl:for-each-group>
                </xsl:for-each-group>
                <xsl:copy-of select="$n-pattern"/>
                <xsl:if test="not($rebuilt-integer-sequence = tan:n)">
                    <n class="rebuilt" xmlns="tag:textalign.net,2015:ns">
                        <xsl:value-of select="$rebuilt-integer-sequence"/>
                    </n>
                </xsl:if>
                
                <xsl:apply-templates select="$source-group-and-sort-pattern"
                    mode="regroup-and-re-sort-divs">
                    <xsl:with-param name="items-to-group-and-sort" tunnel="yes"
                        select="$children-divs"/>
                    <xsl:with-param name="n-pattern" tunnel="yes" select="$n-pattern"/>
                    <xsl:with-param name="qs-to-anchors-to-drop" tunnel="yes"
                        select="$class-2-ref-anchors-to-move-here/@q"/>
                </xsl:apply-templates>
                
                <!-- Class 2 anchors correspond to annotations. Because annotations generally
                fall beside or after the main text (i.e., the main text comes first), we move 
                the ref anchors to the end, here. -->
                <xsl:copy-of select="$class-2-ref-anchors-to-move-here"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tan:ref[not(tan:n)][@q]" mode="input-pass-3">
        <!-- between the version wrapper <div> and this template, we calculate @qs for anchors that
        pertain to works, not merely, versions, and we drop them from here, their version location. -->
        <xsl:param name="qs-to-anchors-to-drop" tunnel="yes" as="xs:string*"/>
        <xsl:if test="not(@q = $qs-to-anchors-to-drop)">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:ref[tan:n] | tan:orig-ref" mode="input-pass-3">
        <xsl:if test="not($suppress-refs)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:n" mode="input-pass-3">
        <xsl:if test="not(exists(preceding-sibling::tan:n)) and $add-display-n">
            <display-n xmlns="tag:textalign.net,2015:ns">
                <xsl:value-of select="../(@orig-n, @n)[1]"/>
            </display-n>
        </xsl:if>
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="tan:body/text() | tan:div/text()" mode="input-pass-3">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="tan:ref/text()" mode="input-pass-3">
        <xsl:variable name="constituent-ns" select="../tan:n"/>
        <xsl:variable name="new-ns" as="xs:string*">
            <xsl:for-each select="$constituent-ns">
                <xsl:variable name="this-pos" select="position()"/>
                <xsl:variable name="this-n" select="."/>
                <xsl:choose>
                    <xsl:when
                        test="$this-pos = $levels-to-convert-to-aaa and $this-n castable as xs:integer">
                        <xsl:value-of select="tan:int-to-aaa(xs:integer($this-n))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($new-ns, ' ')"/>
    </xsl:template>
    
    
    <!-- Grouping and sorting sources: place aligned source-specific parts of a TAN-A_merge file into a particular grouping or sort order -->
    <!-- This set of templates is supposed to apply to $source-group-and-sort-pattern, which is an XML fragment consisting of <group>, <alias>, and <idref> -->
    <!-- <idref> contains the idref to a source; <alias> is essentially just the name of the <group> it is a child of -->
    
    <xsl:template match="tan:source-pattern" mode="regroup-and-re-sort-divs regroup-and-re-sort-heads">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="tan:group" mode="regroup-and-re-sort-heads">
        <xsl:param name="items-to-group-and-sort" tunnel="yes" as="element()*"/>
        
        <xsl:variable name="these-idrefs" select="tan:idref"/>
        
        <xsl:variable name="descendant-idrefs" select=".//tan:idref"/>
        <xsl:variable name="items-yet-to-place"
            select="$items-to-group-and-sort[(tan:src, @src) = $descendant-idrefs]"/>
        <xsl:variable name="these-class-values" select="string-join((@alias-id), ' ')"/>
        
        <xsl:if test="exists($items-yet-to-place) or $fill-defective-merges">
            <xsl:copy>
                <xsl:if test="string-length($these-class-values) gt 0">
                    <xsl:attribute name="class" select="$these-class-values"/>
                </xsl:if>
                <xsl:copy-of select="tan:alias"/>
                <div class="group-items">
                    <xsl:apply-templates select="* except tan:alias" mode="#current">
                        <xsl:with-param name="items-to-group-and-sort" tunnel="yes"
                            select="$items-yet-to-place"/>
                    </xsl:apply-templates>
                </div>

            </xsl:copy>
        </xsl:if>

    </xsl:template>
    
    <xsl:template match="tan:group" mode="regroup-and-re-sort-divs">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:alias" mode="regroup-and-re-sort-heads">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="tan:alias" mode="regroup-and-re-sort-divs"/>
    
    <xsl:template match="tan:idref" mode="regroup-and-re-sort-heads">
        <xsl:param name="items-to-group-and-sort" as="element()*" tunnel="yes"/>
        <xsl:variable name="this-idref" select="."/>
        <xsl:variable name="those-items" select="$items-to-group-and-sort[(tan:src, @src) = $this-idref]"/>
        <xsl:variable name="filler-element" as="element()">
            <head type="#version" class="filler" xmlns="tag:textalign.net,2015:ns">
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:text> </xsl:text>
            </head>
        </xsl:variable>
        <xsl:apply-templates select="$those-items" mode="#current"/>
        <xsl:if test="not(exists($those-items))">
            <xsl:copy-of select="$filler-element"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:idref" mode="regroup-and-re-sort-divs">
        <xsl:param name="items-to-group-and-sort" as="element()*" tunnel="yes"/>
        <xsl:param name="n-pattern" as="element()*" tunnel="yes"/>
        <xsl:variable name="this-idref" select="."/>
        <xsl:variable name="those-divs" select="$items-to-group-and-sort[(tan:src, @src) = $this-idref]"/>
        <xsl:variable name="filler-element" as="element()">
            <div type="#version" class="filler" xmlns="tag:textalign.net,2015:ns">
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:text> </xsl:text>
            </div>
        </xsl:variable>
        <xsl:variable name="items-to-group-and-sort"
            select="
            if (exists($those-divs)) then
            $those-divs
            else
            $filler-element"
        />
        <xsl:variable name="these-alias-ids" select="ancestor::*[@alias-id]/@alias-id"/>
        
        <xsl:if test="exists($those-divs) or $fill-defective-merges">
            <!-- Within a version-wrapper, a given source could easily have many <div>s, so we wrap them up (even singletons) as an <item> -->
            <!-- Each item is given a class value not just for the source id, but for all alias ids, to facilitate toggling divs. -->
            <item xmlns="tag:textalign.net,2015:ns">
                <xsl:attribute name="class" select="string-join(($this-idref, $these-alias-ids), ' ')"/>
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:apply-templates select="$n-pattern" mode="#current">
                    <xsl:with-param name="items-to-group-and-sort" as="element()*"
                        select="$items-to-group-and-sort"/>
                    <xsl:with-param name="filler-element" as="element()?" select="$filler-element"/>
                </xsl:apply-templates>
            </item>
        </xsl:if>
        
    </xsl:template>
    <xsl:template match="tan:primary-ns | tan:n" mode="regroup-and-re-sort-divs">
        <xsl:param name="items-to-group-and-sort" as="element()*"/>
        <xsl:param name="filler-element" as="element()?"/>
        <xsl:variable name="diagnostics" select="false()"/>
        <xsl:variable name="this-src" select="$filler-element/tan:src/text()"/>
        <xsl:variable name="these-ns" select="descendant-or-self::tan:n"/>
        <xsl:variable name="those-divs" select="$items-to-group-and-sort[tan:n = $these-ns]"/>
        <xsl:variable name="divs-of-interest" select="$those-divs[tan:n[1] = $these-ns]"/>
        <xsl:variable name="first-div-of-interest" select="$divs-of-interest[1]"/>
        <xsl:variable name="divs-not-of-interest" select="$those-divs except $divs-of-interest"/>
        <xsl:variable name="divs-of-interest-consolidated"/>
        <xsl:if test="$diagnostics">
            <xsl:message select="'This src: ', $this-src"/>
            <xsl:message select="'These ns: ', $these-ns"/>
            <xsl:message select="'Those divs: ', $those-divs"/>
            <xsl:message select="'Divs of interest: ', $divs-of-interest"/>
            <xsl:message
                select="'Extra divs of interest: ', ($divs-of-interest except $first-div-of-interest)"
            />
        </xsl:if>
        <xsl:apply-templates select="$divs-of-interest[1]" mode="input-pass-3">
            <xsl:with-param name="extra-divs-of-interest"
                select="$divs-of-interest except $first-div-of-interest"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="$divs-not-of-interest" mode="#current">
            <xsl:with-param name="context-ns" select="$these-ns"/>
        </xsl:apply-templates>
        <xsl:if test="not(exists($those-divs)) and $fill-defective-merges">
            <div xmlns="tag:textalign.net,2015:ns">
                <xsl:copy-of select="$filler-element/@*"/>
                <xsl:copy-of select="$filler-element/*"/>
                <xsl:copy-of select="$these-ns"/>
                <xsl:copy-of select="$filler-element/text()"/>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:div" mode="regroup-and-re-sort-divs">
        <xsl:param name="context-ns" as="element()*"/>
        <!-- These are divs not of interest, because they've been marked earlier. But we take this step to calculate rowspan -->
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="'continuation'"/>
            <xsl:copy-of select="tan:src"/>
            <xsl:copy-of select="$context-ns"/>
        </xsl:copy>
    </xsl:template>
    
    

    <!-- PASS 4 -->
    <!-- make adjustments in the conversion from TAN to HTML -->

    <!-- It will be a common practice to tag an html <div> according to the class types of the source id; the following functions expedite that process -->
    <xsl:function name="tan:class-val-for-src-id" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: all relevant class values -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="results" as="xs:string*">
            <!--<xsl:value-of select="tan:class-val-for-alias-group($src-id)"/>-->
            <xsl:value-of select="tan:class-val-for-source($src-id)"/>
            <xsl:value-of select="tan:class-val-for-group-item-number($src-id)"/>
        </xsl:variable>
        <xsl:value-of select="string-join($results, ' ')"/>
    </xsl:function>
    <xsl:function name="tan:class-val-for-alias-group" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the alias name and position number -->
        <!-- If no alias can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="this-pattern-match" select="tan:get-pattern-match($src-id)"/>
        <!-- There should only be one value of $this-alias, but we set it up as if there 
        might be more, just in case we wish to expand to multiple aliases in the future. -->
        <xsl:variable name="this-alias"
            select="
                for $i in $this-pattern-match/preceding-sibling::tan:alias
                return
                    'alias--' || $i"
        />
        <!--<xsl:variable name="this-alias-pos" select="index-of($alias-names, $this-alias)"/>-->
        <xsl:variable name="this-alias-id" select="$this-pattern-match/../@alias-id"/>
        <!--<xsl:if test="exists($this-alias)">
            <!-\-<xsl:value-of
                select="concat('alias-\\-', string($this-alias-pos), ' alias-\\-', $this-alias)"/>-\->
            <xsl:value-of
                select="concat('alias-\-', string($this-alias-pos), ' alias-\-', $this-alias)"/>
        </xsl:if>-->
        <!--<xsl:value-of select="string-join(($this-alias, $this-alias-id), ' ')"/>-->
        <xsl:value-of select="string-join($this-alias-id, ' ')"/>
    </xsl:function>
    <xsl:function name="tan:class-val-for-group-item-number" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the item's position in the group -->
        <!-- If no pattern idref can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="this-pattern-match" select="tan:get-pattern-match($src-id)"/>
        <xsl:variable name="preceding-items"
            select="$this-pattern-match/preceding-sibling::tan:idref"/>
        <xsl:if test="exists($this-pattern-match)">
            <xsl:value-of select="concat('groupitem--', string(count($preceding-items) + 1))"/>
        </xsl:if>
    </xsl:function>
    <xsl:function name="tan:class-val-for-source" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the alias name and position number -->
        <!-- If no idref can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:value-of select="concat('src--', $src-id)"/>
    </xsl:function>
    <xsl:function name="tan:get-pattern-match" as="item()*">
        <!-- Input: source ids -->
        <!-- Output: the corresponding <idref> nodes in the source group and sort pattern -->
        <xsl:param name="src-ids" as="xs:string*"/>
        <xsl:sequence select="$source-group-and-sort-pattern//tan:idref[. = $src-ids]"/>
    </xsl:function>


    <xsl:template match="tan:TAN-T_merge" mode="tan-to-html-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="$self-resolved/*/tan:head/tan:name[not(@norm)]"
                mode="tan-to-html-pass-2-title"/>
            <xsl:apply-templates select="$self-resolved/*/tan:head/tan:desc"
                mode="tan-to-html-pass-2-title"/>
            <xsl:if test="$add-bibliography">
                <xsl:copy-of select="$source-bibliography"/>
            </xsl:if>
            <hr/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:head/tan:name" mode="tan-to-html-pass-2-title">
        <h1>
            <xsl:copy-of select="@xml:lang"/>
            <xsl:value-of select="."/>
        </h1>
    </xsl:template>
    <xsl:template match="tan:head/tan:desc" mode="tan-to-html-pass-2-title">
        <div class="desc title">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>

    <xsl:variable name="source-bibliography" as="element()">
        <div class="bibl">
            <h2 class="label">Bibliography</h2>
            <!-- first, the key -->
            <div class="bibl-key">
                <xsl:for-each select="$src-id-sequence">
                    <xsl:variable name="this-src-id" select="."/>
                    <div class="bibl-key-item">
                        <div class="{tan:class-val-for-alias-group($this-src-id)}">
                            <div class="{tan:class-val-for-src-id($this-src-id)}">
                                <xsl:value-of select="$this-src-id"/>
                            </div>
                        </div>
                        <div class="name">
                            <xsl:value-of
                                select="$input-pass-1/tan:TAN-T[@src = $this-src-id]/tan:head/tan:source/tan:name[not(@common)][1]"
                            />
                        </div>
                    </div>
                </xsl:for-each>
            </div>
            <!-- second, the sorted bibliography -->
            <div class="bibl-body">
                <xsl:for-each-group select="$input-pass-1/tan:TAN-T/tan:head/tan:source"
                    group-by="tan:name[not(@common)][1]">
                    <xsl:sort select="current-grouping-key()"/>
                    <div class="bibl-item">
                        <div class="name">
                            <xsl:value-of select="current-grouping-key()"/>
                        </div>
                        <xsl:for-each-group select="current-group()/tan:desc" group-by=".">
                            <div class="desc">
                                <xsl:value-of select="."/>
                            </div>
                        </xsl:for-each-group>
                    </div>
                </xsl:for-each-group>
            </div>
        </div>
    </xsl:variable>

    <!-- The source controller -->
    <xsl:template match="html:div[tokenize(@class, ' ') = 'control']" mode="tan-to-html-pass-2"
        priority="1">
        <xsl:copy>
            <xsl:attribute name="class" select="'control-wrapper'"/>
            <xsl:if test="$add-controller-label">
                <h2 class="label">Sources</h2>
            </xsl:if>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="class" select="string-join((@class, 'sortable'), ' ')"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
            <div class="help">
                <div class="label">Help</div>
                <div>Above are the sources, or groups of sources, that have been aligned. Click a
                    box to expand it and see what other groups or sources are included. To put
                    sources in a different order, drag the appropriate box. Click any checkbox to
                    turn a group of sources, or an individual source, on and off; click on any
                    source id to learn more about it.</div>
                <xsl:if test="$add-controller-options">
                    <div>Click other options, below, to adjust your reading experience.</div>
                </xsl:if>
                <xsl:if test="$render-as-diff-threshhold gt 0 and $render-as-diff-threshhold lt 1">
                    <div>If at any point in the transcription, a group of sources have text that is
                            <xsl:value-of select="format-number($render-as-diff-threshhold, '0%')"/>
                        in common, they are collapsed into a single presentation format, with
                        differences shown, if any. These are distinguished by the source names
                        joined by a +. If you click the ... in the cell, you will get a table of
                        statistics and a source controller. Click a box to turn a source off or on
                        within the div. Click the formatted Tt to apply a format to a different
                        version. When you hover your mouse over a highlighted change, a tooltip will
                        appear showing you which sources attest to that reading.</div>
                </xsl:if>
                <div>This HTML page was generated on <xsl:value-of select="$today-MDY"/> at
                        <xsl:value-of select="$now"/> by <a href="{$stylesheet-url}">
                        <xsl:value-of select="$stylesheet-name"/></a>, an application of the <a
                        href="http://textalign.net">Text Alignment Network</a>. If the page does not
                    have exactly the sources or features you want, re-run the application, changing
                    the parameters to suit what you want. Because its main input is a <a
                        href="{$doc-uri}">TAN-A file</a>, you may find that making changes to
                    &lt;source>s, &lt;adjustments>, and &lt;alias> is sufficient.</div>
                
            </div>
            <xsl:if test="$add-controller-options">
                <div class="options">
                    <div class="label">Other options</div>
                    <div class="option-group">
                        <xsl:copy-of
                            select="tan:add-class-switch('table', 'layout-fixed', 'Table layout fixed', $table-layout-fixed)"/>
                        <div class="option-item">
                            <div>Table width <input id="tableWidth" type="number" min="50" max="10000"
                                    value="100"/>%</div>
                        </div>
                        <xsl:copy-of
                            select="tan:add-class-switch('.add', 'hidden', 'Hide additions', true())"/>
                        <xsl:copy-of
                            select="tan:add-class-switch('.milestone', 'hidden', 'Hide milestones', true())"/>
                        <xsl:copy-of
                            select="tan:add-class-switch('.note', 'hidden', 'Hide annotations', true())"/>
                        <xsl:copy-of
                            select="tan:add-class-switch('.ref', 'hidden', 'Hide references', true())"/>
                        <xsl:copy-of
                            select="tan:add-class-switch('.rdg', 'hidden', 'Hide variant readings', true())"
                        />
                    </div>
                </div>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="tan:add-class-switch" as="element()?">
        <!-- Input: three strings and a boolean -->
        <!-- Output: an html switch with a div.elementName for the first string, a div.className for the second,
            a plain div for the third, then an on/off switch set to the default value of the boolean. The effect is that
            an accompanying JavaScript algorithm targets elements that match the selector and toggles the class name. 
        -->
        <xsl:param name="elementSelector" as="xs:string"/>
        <xsl:param name="className" as="xs:string"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="default-on" as="xs:boolean"/>
        <div class="option-item">
            <div class="classSwitch">
                <div class="elementName" style="display:none">
                    <xsl:value-of select="$elementSelector"/>
                </div>
                <div class="className" style="display:none">
                    <xsl:value-of select="$className"/>
                </div>
                <div>
                    <xsl:value-of select="$label"/>
                </div>
                <div class="on">
                    <xsl:if test="$default-on = false()">
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:if>
                    <xsl:text>☑</xsl:text>
                </div>
                <div class="off">
                    <xsl:if test="$default-on = true()">
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:if>
                    <xsl:text>☐</xsl:text>
                </div>
            </div>
        </div>
    </xsl:function>
    <xsl:template match="tan:head/tan:src | tan:group/tan:alias" mode="tan-to-html-pass-2">
        <!-- For filtering and reording the merged contents -->
        <div class="switch">
            <div class="on">☑</div>
            <div class="off" style="display:none">☐</div>
        </div>
        <div class="label">
            <xsl:value-of select="replace(., '_', ' ')"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:desc" mode="tan-to-html-pass-2">
        <div class="desc"><xsl:value-of select="."/></div>
    </xsl:template>
    <!-- tan:TAN-T_merge/*[@class = 'control']//tan:group[not(tan:alias)] -->
    <xsl:template match="tan:TAN-T_merge/*[@class = 'control']//tan:group" mode="tan-to-html-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
             <xsl:attribute name="draggable" select="'true'"/> 
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*[@class = 'group-items']" mode="tan-to-html-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="string-join((@class, 'sortable'), ' ')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:head" mode="tan-to-html-pass-2">
        <xsl:variable name="extra-class-values" as="xs:string*">
            <xsl:value-of
                select="concat('groupitem--', string(count(preceding-sibling::tan:head) + 1))"
            />
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="draggable" select="'true'"/>
            <xsl:attribute name="class" select="string-join((@class, $extra-class-values), ' ')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:body" mode="tan-to-html-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$tables-via-css">
                    <xsl:apply-templates mode="tan-to-html-pass-2-css-tables"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="tan-to-html-pass-2-html-tables"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()" mode="tan-to-html-pass-2-html-tables tan-to-html-pass-2-css-tables">
        <xsl:value-of select="replace(., '_', ' ')"/>
    </xsl:template>
    <xsl:template match="tan:n | tan:src | tan:ref[tan:n]" mode="tan-to-html-pass-2-html-tables tan-to-html-pass-2-css-tables">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:variable name="preceding-siblings" select="preceding-sibling::*[name(.) = $this-name]"/>
        <xsl:if test="not(. = $preceding-siblings)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:div/tan:ref[not(tan:n)][@q or @id]" mode="tan-to-html-pass-2-html-tables-post-table">
        <!-- This <ref> is an anchor to a class-2 annotation -->
        <xsl:variable name="this-corresponding-annotation-ref" as="element()*"
            select="key('q-ref', (@q, @id), $self-expanded/tan:TAN-A)"/>
        <xsl:variable name="this-claim" select="$this-corresponding-annotation-ref/ancestor::tan:claim"/>
        <xsl:variable name="this-claim-component-context"
            select="$this-corresponding-annotation-ref/ancestor::*[parent::tan:claim][1]"/>
        <xsl:variable name="this-claim-component-name" select="name($this-claim-component-context)"/>
        <xsl:variable name="this-claim-component-position"
            select="count($this-claim-component-context/preceding-sibling::*[name() eq $this-claim-component-name]) + 1"
        />
        <xsl:choose>
            <xsl:when test="exists($this-corresponding-annotation-ref)">
                <xsl:apply-templates select="$this-claim" mode="annotation-to-html">
                    <xsl:with-param name="originating-qs" select="@q | @id"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tan:claim" mode="annotation-to-html">
        <xsl:param name="originating-qs" as="xs:string*"/>
        <xsl:variable name="this-claim" select="."/>
        <!-- subject, adverb, verb, object, everything else : all the preceding except items where the context is known -->
        <xsl:variable name="annotation-sequence" select="('subject', 'adverb', 'verb', 'object', 'where', 'when', 'claimant')"/>
        <xsl:variable name="originating-claim-component" select="*[descendant-or-self::*[@q = $originating-qs]][1]"/>
        <xsl:variable name="originating-claim-component-name" select="name($originating-claim-component)"/>
        <xsl:variable name="comparable-claim-components"
            select="*[name(.) = $originating-claim-component-name] except $originating-claim-component"
        />
        <xsl:variable name="applicable-to-only-some-versions" select="exists($originating-claim-component/@src)"/>
        <xsl:variable name="this-claim-resolved" as="element()">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:if test="$applicable-to-only-some-versions">
                    <div class="{$originating-claim-component-name}">
                        <xsl:value-of select="$originating-claim-component/@src || ': '"/>
                    </div>
                </xsl:if>
                <xsl:for-each-group
                    select="* except ($originating-claim-component, $comparable-claim-components)"
                    group-by="name(.)">
                    <xsl:sort
                        select="(index-of($annotation-sequence, current-grouping-key()), 99)[1]"/>
                    <xsl:variable name="this-component-name" select="current-grouping-key()"/>
                    <xsl:variable name="matching-claim-attribute" select="$this-claim/@*[name(.) = $this-component-name]"/>
                    <xsl:variable name="label-strings" as="xs:string*">
                        <xsl:for-each select="current-group()">
                            <xsl:value-of select="string-join(((@work, @src, @scriptum)[1], @ref), ' ')"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="this-label" as="xs:string?">
                        <xsl:choose>
                            <xsl:when test="exists($matching-claim-attribute)">
                                <xsl:value-of select="replace($matching-claim-attribute, '[_-]', ' ')"/>
                            </xsl:when>
                            <xsl:when test="exists(current-group()[@*]) and not(exists(current-group()/@attr))">
                                <xsl:value-of select="tan:commas-and-ands($label-strings)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$this-component-name"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="there-are-multiple-refs" select="count(current-group()//tan:ref) gt 1"/>
                    <xsl:variable name="these-refs" select="current-group()/tan:ref[@q]"/>
                    
                    <div class="{$this-component-name}">
                        <div class="label">
                            <xsl:value-of select="$this-label"/>
                        </div>
                        <xsl:if test="exists($these-refs)">
                            <xsl:for-each select="$self-expanded/tan:TAN-T">
                                <xsl:sort select="(index-of($src-ids, @src), 999999)[1]"/>
                                <xsl:variable name="these-anchors" select="key('q-ref', $these-refs/@q, tan:body)"/>
                                <xsl:variable name="these-divs-prepped-for-html" as="element()*">
                                    <xsl:apply-templates select="$these-anchors/ancestor::tan:div[1]" mode="tan-to-html-pass-1"/>
                                </xsl:variable>
                                <xsl:variable name="this-src" select="@src"/>
                                <xsl:if test="exists($these-anchors)">
                                    <div>
                                        <div class="label">
                                            <xsl:value-of select="$this-src"/>
                                        </div>
                                        <div class="content">
                                            <xsl:apply-templates
                                                select="$these-divs-prepped-for-html"
                                                mode="#current"/>
                                        </div>
                                    </div>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                        <xsl:apply-templates select="current-group()/* except $these-refs" mode="#current">
                            <xsl:with-param name="retain-ref-label" tunnel="yes" select="$there-are-multiple-refs"/>
                        </xsl:apply-templates>
                    </div>
                </xsl:for-each-group>
                <xsl:if test="exists(@cert)">
                    <xsl:variable name="this-cert" select="number(@cert)"/>
                    <div class="certainty">
                        <xsl:choose>
                            <xsl:when test="$this-cert lt 0.25">
                                <xsl:text>(??)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>(?)</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                </xsl:if>
                <xsl:if test="exists($comparable-claim-components)">
                    <div class="{$originating-claim-component-name} see-also">
                        <xsl:apply-templates select="$comparable-claim-components" mode="#current"/>
                    </div>
                </xsl:if>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$this-claim-resolved" mode="tan-to-html-pass-1"/>
    </xsl:template>
    
    <!-- These are items we've already set up in a label, and don't need to be processed further -->
    <xsl:template
        match="tan:object/tan:work | tan:object/tan:scriptum | tan:object/tan:src | tan:subject/tan:work | tan:subject/tan:scriptum | tan:subject/tan:src"
        mode="annotation-to-html"/>
    
    <!-- Drop class 2 anchor <ref>s in class 1 sources -->
    <xsl:template match="tan:div/tan:ref[not(tan:n)]" priority="1" mode="annotation-to-html"/>
    
    <xsl:template match="tan:div" mode="annotation-to-html">
        <xsl:param name="label-to-insert" as="xs:string?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="string-length($label-to-insert) gt 0">
                <div class="label">
                    <xsl:value-of select="$label-to-insert"/>
                </div>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!-- We have provided for the reference system in the claim's <subject> or <object>'s label. -->
    <xsl:template match="tan:div/tan:ref | tan:div/tan:n | tan:div/tan:type" mode="annotation-to-html"/>
    
    <xsl:template match="tan:div/text()[matches(., '\S')]" mode="annotation-to-html">
        <div>
            <xsl:value-of select="."/>
        </div>
    </xsl:template>

    <!-- Build a version wrapper -->
    <!-- For table-based comparison of versions, here begins the creation of the table. The rows are shaped
    by the n patterns, because there may be defective or combined @n values for a set of versions, in which 
    case we need to calculate @rowspan values. Once that grid is formed, the versions are brought together at
    the <td> level, further into the template mode. -->
    <xsl:template match="tan:div[tokenize(@class, ' ') = $version-wrapper-class-name]"
        mode="tan-to-html-pass-2-html-tables">
        <xsl:variable name="n-pattern" as="element()*"
            select="(tan:primary-ns, tan:n[not(contains(@class, 'rebuilt'))])"/>
        <!--<xsl:variable name="these-div-versions"
            select=".//tan:div[tokenize(@class, ' ') = 'version']"/>-->
        <xsl:variable name="these-div-versions" select="tan:item/tan:div"/>
        <xsl:variable name="these-divs-diffed" as="element()*">
            <xsl:choose>
                <xsl:when test="$render-as-diff-threshhold gt 0 and $render-as-diff-threshhold lt 1">
                    <xsl:for-each-group select="$these-div-versions"
                        group-by="
                            for $i in ancestor-or-self::*[tan:src][1]/tan:src[1]
                            return
                                $source-group-and-sort-pattern//tan:group[tan:idref = $i]/tan:alias">
                        <xsl:variable name="is-diff" select="count(current-group()) eq 2"/>
                        <xsl:variable name="these-raw-texts" as="xs:string*"
                            select="
                                for $i in current-group()
                                return
                                    string-join($i/descendant-or-self::tan:div/text())"/>
                        <xsl:variable name="these-texts-normalized-1"
                            select="
                                if (count(($diff-and-collate-input-batch-replacements)) gt 0) then
                                    (for $i in $these-raw-texts
                                    return
                                        tan:batch-replace($i, ($diff-and-collate-input-batch-replacements)))
                                else
                                    $these-raw-texts"/>

                        <xsl:variable name="finalized-texts-to-compare" as="xs:string*"
                            select="
                                if ($ignore-case-differences) then
                                    (for $i in $these-texts-normalized-1
                                    return
                                        lower-case($i))
                                else
                                    $these-texts-normalized-1"/>

                        <xsl:variable name="these-idrefs"
                            select="current-group()/ancestor-or-self::*[tan:src][1]/tan:src[1]"/>
                        <xsl:variable name="this-diff-or-collation" as="element()?">
                            <xsl:choose>
                                <xsl:when
                                    test="
                                        some $i in $finalized-texts-to-compare
                                            satisfies not(matches($i, '\S'))"/>
                                <xsl:when test="$is-diff">
                                    <xsl:sequence
                                        select="tan:adjust-diff(tan:diff($finalized-texts-to-compare[1], $finalized-texts-to-compare[2], $snap-to-word))"
                                    />
                                </xsl:when>
                                <xsl:when test="count(current-group()) gt 2">
                                    <xsl:sequence
                                        select="tan:collate($finalized-texts-to-compare, $these-idrefs, true(), true(), true(), $snap-to-word)"
                                    />
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="this-common-text"
                            select="$this-diff-or-collation/(tan:common | tan:c/tan:txt)"/>
                        <xsl:variable name="this-full-text"
                            select="$this-diff-or-collation/(tan:common | tan:a | tan:b | */tan:txt)"/>
                        <xsl:variable name="common-text-length"
                            select="string-length(string-join($this-common-text))"/>
                        <xsl:variable name="full-text-length"
                            select="string-length(string-join($this-full-text))"/>
                        <xsl:variable name="this-ratio-of-commonality"
                            select="
                                if ($full-text-length gt 0) then
                                    $common-text-length div $full-text-length
                                else
                                    0"/>
                        <xsl:choose>
                            <xsl:when
                                test="$this-ratio-of-commonality gt $render-as-diff-threshhold">

                                <xsl:variable name="this-diff-or-collation-statted"
                                    select="tan:infuse-diff-and-collate-stats($this-diff-or-collation, (), $include-venns)"/>

                                <xsl:variable name="this-diff-or-collate-as-html" as="element()">
                                    <xsl:apply-templates select="$this-diff-or-collation-statted"
                                        mode="diff-and-collate-to-html">
                                        <xsl:with-param name="last-wit-idref" tunnel="yes"
                                            select="
                                                if ($first-version-is-of-primary-interest) then
                                                    $these-idrefs[1]
                                                else
                                                    $these-idrefs[last()]"
                                        />
                                        <xsl:with-param name="raw-texts" tunnel="yes"
                                            select="
                                                if ($is-diff) then
                                                    $these-raw-texts
                                                else
                                                    if ($first-version-is-of-primary-interest) then
                                                        $these-raw-texts[1]
                                                    else
                                                        $these-raw-texts[last()]"
                                        />
                                    </xsl:apply-templates>
                                </xsl:variable>
                                
                                <div n="{position()}"
                                    class="version {string-join($these-idrefs, ' ')} {string-join($these-idrefs, '+')}"
                                    colspan="{count(current-group())}">
                                    <!--<test05e>
                                        <this-diff-or-collation><xsl:copy-of select="$this-diff-or-collation"/></this-diff-or-collation>
                                        <ctl><xsl:value-of select="$common-text-length"/></ctl>
                                        <ftl><xsl:value-of select="$full-text-length"/></ftl>
                                        <commonality><xsl:copy-of select="$this-ratio-of-commonality"/></commonality>
                                        <statted><xsl:copy-of select="$this-diff-or-collation-statted"/></statted>
                                        <as-html><xsl:copy-of select="$this-diff-or-collate-as-html"/></as-html>
                                    </test05e>-->
                                    <xsl:copy-of select="$these-idrefs"/>
                                    <xsl:copy-of select="current-group()[1]/*"/>
                                    <xsl:apply-templates select="$this-diff-or-collate-as-html"
                                        mode="adjust-diff-or-collate-for-merged-display"/>
                                </div>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="current-group()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$these-div-versions"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <div>
            <xsl:copy-of select="@*"/>
            <div class="meta">
                <xsl:apply-templates select="* except tan:group" mode="tan-to-html-pass-2-html-tables-pre-table"/>
            </div>
            <!--<div class="test05a"><xsl:copy-of select="$these-div-versions"/></div>-->
            <!--<div class="test05b"><xsl:copy-of select="$these-divs-diffed"/></div>-->
            <table>
                <xsl:if test="$table-layout-fixed">
                    <xsl:attribute name="class" select="'layout-fixed'"/>
                </xsl:if>
                
                <tbody>
                    <xsl:apply-templates select="$n-pattern"
                        mode="tan-to-html-pass-2-html-tables-tr">
                        <!--<xsl:with-param name="div-versions" select="$these-div-versions" tunnel="yes"/>-->
                        <xsl:with-param name="div-versions" select="$these-divs-diffed" tunnel="yes"/>
                    </xsl:apply-templates>
                </tbody>
            </table>
            <div class="meta">
                <xsl:apply-templates select="* except tan:group" mode="tan-to-html-pass-2-html-tables-post-table"/>
            </div>
        </div>
    </xsl:template>
    
    <!-- Get rid of the <h2>Comparison header, as well as the 2nd column in the statistics table, with the URI -->
    <xsl:template match="html:h2 | html:table[@class = 'e-stats']/html:thead/html:tr/html:th[2] | 
        html:table[@class = 'e-stats']/html:tbody/html:tr/html:td[2]" 
        mode="adjust-diff-or-collate-for-merged-display"/>
    <xsl:template match="html:*[html:div[@class = ('collation', 'e-diff')]]" mode="adjust-diff-or-collate-for-merged-display">
        <xsl:variable name="this-collation" select="html:div[@class = ('collation', 'e-diff')]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <div class="collation-head">
                <div class="label">...</div>
                <xsl:apply-templates select="$this-collation/preceding-sibling::node()" mode="#current"/>
            </div>
            <xsl:apply-templates select="$this-collation/(self::*, following-sibling::node())" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:primary-ns | tan:n" mode="tan-to-html-pass-2-html-tables-tr">
        <xsl:param name="div-versions" as="element()*" tunnel="yes"/>
        <xsl:variable name="these-ns" select="descendant-or-self::tan:n"/>
        <xsl:variable name="these-refs" select="../tan:ref"/>
        <!-- It is important that only the first n matches, otherwise you get a primary <div> lumped in with a continuation. -->
        <xsl:variable name="these-div-versions" select="$div-versions[tan:n[1] = $these-ns]"/>
        <tr>
            <td class="label">
                <xsl:for-each select="$these-refs, $these-ns">
                    <div class="{name(.)}">
                        <xsl:value-of select="text()"/>
                    </div>
                </xsl:for-each>
            </td>
            <xsl:apply-templates select="$these-div-versions" mode="tan-to-html-pass-2-html-tables"/>
        </tr>
    </xsl:template>
    
    <xsl:template
        match="*:div[tokenize(@class, ' ') = ('version', 'filler', 'continuation', 'consolidated')]"
        mode="tan-to-html-pass-2-html-tables">
        <!-- This template is for the leafmost divs -->
        <xsl:variable name="is-continuation" select="tokenize(@class, ' ') = 'continuation'"/>
        <xsl:variable name="these-srcs" select="ancestor-or-self::*[tan:src][1]/tan:src"/>
        <xsl:variable name="this-pattern-marker"
            select="$source-group-and-sort-pattern//tan:idref[. = $these-srcs]"/>
        <xsl:variable name="top-level-pattern" select="$source-group-and-sort-pattern/*[descendant-or-self::tan:idref[. = $these-srcs]]"/>
        <xsl:variable name="following-siblings" select="following-sibling::tan:div"/>
        <xsl:variable name="first-following-noncontinuation-sibling"
            select="$following-siblings[not(tokenize(@class, ' ') = 'continuation')][1]"/>
        <xsl:variable name="following-continuations"
            select="$following-siblings except $first-following-noncontinuation-sibling/(self::*, following-sibling::*)"/>
        <xsl:variable name="these-alias-ids" select="ancestor::tan:group/tan:alias"/>
        
        
        <!-- A <td> class should have at least the source class and the groupitem class, e.g., 
        class="src-/-grc-xyz groupitem-/-1" (double hyphens escaped, to keep this comment valid). 
        The first makes sure that the <td> changes position if the
        user changes the sequence of the sources. The second makes sure that the right opacity is applied
        to the background color, determined by the corresponding <col> in <colgroup>. The groupitem number
        has to do with what position the source is within its alias group. -->
        
        <xsl:variable name="these-src-classes"
            select="
                for $i in $these-srcs
                return
                    tan:class-val-for-source($i)"
        />
        <!-- We needed this variable at one time, but not now; but there may be a time -->
        <xsl:variable name="these-group-classes"
            select="
                for $i in $these-srcs
                return
                    tan:class-val-for-group-item-number($i)"
        />

        <xsl:variable name="these-class-additions" as="xs:string*" select="$these-src-classes, $top-level-pattern/@alias-id"/>
        <xsl:variable name="this-has-text"
            select="exists(text()[matches(., '\S')]) or exists(tei:*) or exists(html:div/html:div[@class = ('collation', 'e-diff')])"
        />
        
        <xsl:variable name="diagnostics" select="false()"/>
        <xsl:if test="$diagnostics">
            <xsl:message select="'Diagnostics on, template mode tan-to-html-pass-2-html-tables on tan:div'"/>
            <xsl:message select="'This element: ', tan:shallow-copy(., 4)"/>
            <xsl:message select="'This is continuation:', $is-continuation"/>
            <xsl:message select="'These srcs: ' || $these-srcs"/>
            <xsl:message select="'This pattern marker:', $this-pattern-marker"/>
            <xsl:message select="'Top-level pattern:', $top-level-pattern"/>
            <xsl:message select="'These alias ids:', $these-alias-ids"/>
            <xsl:message select="'This has text:', $this-has-text"/>
            <xsl:message select="'This src class:', $these-src-classes"/>
            <xsl:message select="'This group class:', $these-group-classes"/>
            <xsl:message select="'Class additions:', $these-class-additions"/>
        </xsl:if>
        
        <xsl:if test="not($is-continuation)">
            <td>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="class"
                    select="string-join((@class, $these-class-additions), ' ')"/>
                <xsl:if test="exists($following-continuations)">
                    <xsl:attribute name="rowspan" select="count($following-continuations) + 1"/>
                </xsl:if>
                <!--<test05b><xsl:copy-of select="."/></test05b>-->
                <xsl:choose>
                    <xsl:when test="$this-has-text and exists($top-level-pattern)">
                        <xsl:apply-templates select="$top-level-pattern" mode="build-td-divs">
                            <xsl:with-param name="stop-at" tunnel="yes" select="$these-srcs"/>
                            <xsl:with-param name="version-div" tunnel="yes" select="."/>
                            <xsl:with-param name="src-id" tunnel="yes" select="$these-srcs"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="node() except (tan:type | tan:display-n | tan:n)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="* | text()"
        mode="build-td-divs tan-to-html-pass-2-html-tables-pre-table tan-to-html-pass-2-html-tables-post-table">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:group" mode="build-td-divs">
        <xsl:param name="src-id" tunnel="yes" as="element()*"/>
        <xsl:param name="version-div" tunnel="yes" as="element()?"/>
        <xsl:variable name="this-idref" select="tan:idref[. = $src-id]"/>
        <xsl:if test="exists(descendant::tan:idref[. = $src-id])">
            <div class="{@alias-id}">
                <xsl:apply-templates mode="#current"/>
            </div>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="tan:idref" mode="build-td-divs">
        <xsl:param name="version-div" tunnel="yes" as="element()?"/>
        <xsl:param name="src-id" tunnel="yes" as="element()*"/>
        <xsl:variable name="this-is-collate-or-diff" select="count($src-id) gt 1"/>
        <xsl:variable name="src-id-of-interest"
            select="
                if (not($this-is-collate-or-diff)) then
                    $src-id
                else
                    if ($first-version-is-of-primary-interest) then
                        $src-id[1]
                    else
                        $src-id[last()]"
        />
        <xsl:variable name="build-this" select=". = $src-id-of-interest"/>
        <xsl:variable name="this-pos" select="count(preceding-sibling::*/(self::tan:idref | self::tan:group)) + 1"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode build-td-divs for tan:idref'"/>
            <xsl:message select="'This element:', ."/>
            <xsl:message select="'version div: ', $version-div"/>
            <xsl:message select="'src id(s):', $src-id"/>
            <xsl:message select="'src id of interest: ', $src-id-of-interest"/>
            <xsl:message select="'Build this element?', $build-this"/>
            <xsl:message select="'This pos:', $this-pos"/>
        </xsl:if>
        
        <xsl:if test="$build-this">
            <!-- We don't copy the source class identifier because we've done that on the ancestral <td>. But we do copy
            the src id as a label -->
            <div class="groupitem--{$this-pos}">

                <div class="label">
                    <xsl:value-of select="string-join($src-id, ' + ')"/>
                </div>
                <xsl:choose>
                    <xsl:when test="$this-is-collate-or-diff">
                        <!-- There are some preliminary <src>, <type>, <n> elements, but the main meat of the
                        diff or collation is inside an html <div> -->
                        <xsl:copy-of select="$version-div/html:div"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates
                            select="$version-div/(node() except (tan:type | tan:display-n | tan:n))"
                            mode="wrap-leaf-text"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </div>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="text()[matches(., '\S')]" mode="wrap-leaf-text">
        <div class="text">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    
    <xsl:template
        match="tan:div[tokenize(@class, ' ') = ($version-wrapper-class-name)]"
        mode="tan-to-html-pass-2-css-tables">
        <xsl:variable name="table-row-cells" select="tan:item"/>
        <xsl:variable name="width-needs-to-be-allocated" select="count($table-row-cells) gt 1"/>
        <xsl:variable name="these-text-nodes"
            select="
                if ($calculate-width-at-td-or-leaf-div-level) then
                    descendant-or-self::tan:div[tokenize(@class, ' ') = 'version']/(text(), tei:*, tan:common, tan:a, tan:b, tan:u, tan:c)
                else
                    ()"
        />
        <xsl:variable name="all-text-norm" select="normalize-space(string-join($these-text-nodes))"/>
        <xsl:variable name="this-string-length" select="string-length($all-text-norm)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="containing-text-string-length" tunnel="yes"
                    select="
                        if ($width-needs-to-be-allocated) then
                            $this-string-length
                        else
                            ()"
                />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:item" mode="tan-to-html-pass-2-css-tables">
        <xsl:param name="containing-text-string-length" tunnel="yes"/>
        <xsl:variable name="these-text-nodes"
            select="
                if ($calculate-width-at-td-or-leaf-div-level) then
                    descendant-or-self::tan:div[tokenize(@class, ' ') = 'version']/(text(), tei:*, tan:common, tan:a, tan:b, tan:u, tan:c)
                else
                    ()"
        />
        <xsl:variable name="all-text-norm" select="normalize-space(string-join($these-text-nodes))"/>
        <xsl:variable name="this-string-length" select="string-length($all-text-norm)"/>
        <xsl:variable name="this-group-item-class"
            select="tan:class-val-for-group-item-number(tan:src)"/>
        <xsl:variable name="these-alias-class-values" select="tokenize(@class, ' ')[matches(., '^alias--')]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$calculate-width-at-td-or-leaf-div-level and $containing-text-string-length gt 0">
                <xsl:attribute name="style"
                    select="concat('width: ', format-number(($this-string-length div $containing-text-string-length), '0.0%'))"
                />
            </xsl:if>
            <!-- Sept. 2020: the impetus for the following comment has been revised, but the nested div
            structure has not been touched. -->
            <!-- When we use tables, we can achieve overlays of two background colors simply
            by assigning one background color to <colgroup> and then another to a <td> 
            inside that column. But to achieve this with <div> and css tables, the two overlays 
            must be created through a pair of <div>s, one nesting in the other. We cannot use
            the <div> that has a width value in @style, because the height of the nested <div>
            might be shorter than its parent, and so leave unmasked background color.
            -->
            <div class="{string-join($these-alias-class-values, ' ')}">
                <div class="{$this-group-item-class}">
                    <xsl:apply-templates mode="#current"/>
                </div>
            </div>
        </xsl:copy>
    </xsl:template>



    <xsl:variable name="src-count-width-css" as="xs:string*">td.version { width: <xsl:value-of
            select="format-number((1 div count($input-pass-1)), '0.0%')"/>}</xsl:variable>
    <xsl:variable name="src-length-width-css" as="xs:string*">
        <xsl:variable name="total-length"
            select="string-length(tan:text-join($input-pass-1/tan:TAN-T/tan:body))"/>
        <xsl:for-each select="$input-pass-1">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="this-length"
                select="string-length(tan:text-join(tan:TAN-T/tan:body))"/>
            <xsl:value-of
                select="concat('td.src--', $this-src-id, '{ width: ', format-number(($this-length div $total-length), '0.0%'), '}')"
            />
        </xsl:for-each>
    </xsl:variable>
    <xsl:template match="html:head" mode="revise-infused-template">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <style>
                table{
                    table-layout: auto;
                }
                .layout-fixed {
                    table-layout: fixed;
                }
                <xsl:if test="$imprint-color-css">
                    <xsl:apply-templates select="$source-group-and-sort-pattern" mode="source-group-and-sort-pattern-to-css-colors"/>
                </xsl:if>
            </style>
            <xsl:choose>
                <xsl:when test="$td-widths-proportionate-to-td-count">
                    <style><xsl:value-of select="$src-count-width-css"/></style>
                </xsl:when>
                <xsl:when test="$td-widths-proportionate-to-string-length">
                    <style><xsl:value-of select="$src-length-width-css"/></style>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="html:body/html:div[text() = 'new-content']" mode="revise-infused-template"
    />
    
    <xsl:template match="node()" mode="source-group-and-sort-pattern-to-css-colors">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="*[@color]" mode="source-group-and-sort-pattern-to-css-colors">
        <xsl:variable name="this-id" select="(@alias-id, text())[1]"/>
        <xsl:value-of select="'.' || $this-id || '{background-color:' || @color || '}&#xa;'"/>
        <xsl:value-of select="'td.' || $this-id || '{border:2px solid ' || @color || '}&#xa;'"/>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    
    <xsl:template match="/" priority="1" use-when="not($output-diagnostics-on)">
        <xsl:copy-of select="$final-output"/>
    </xsl:template>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Diagnostics on for ' || static-base-uri()"/>
        <diagnostics>
            <!--<template-url-resolved><xsl:value-of select="$template-url-resolved"/></template-url-resolved>-->
            <!--<out-dir-rel-cat-input><xsl:value-of select="$output-directory-relative-to-catalyzing-input"/></out-dir-rel-cat-input>-->
            <!--<out-dir-rel-actual-input><xsl:value-of select="$output-directory-relative-to-actual-input"/></out-dir-rel-actual-input>-->
            <!--<out-dir-rel-template><xsl:value-of select="$output-directory-relative-to-template"/></out-dir-rel-template>-->
            <!--<out-dir-default><xsl:value-of select="$default-output-directory-resolved"/></out-dir-default>-->
            <!--<output-dir-resolved><xsl:value-of select="$output-directory-resolved"/></output-dir-resolved>-->
            <!--<output-url-resolved><xsl:value-of select="$output-url-resolved"/></output-url-resolved>-->
            <valid-src-work-vocab><xsl:copy-of select="$valid-src-work-vocab"/></valid-src-work-vocab>
            <valid-srcs-by-work><xsl:copy-of select="$valid-srcs-by-work"/></valid-srcs-by-work>
            <alias-based-group-and-sort-pattern><xsl:copy-of select="$alias-based-group-and-sort-pattern"/></alias-based-group-and-sort-pattern>
            <src-id-sequence><xsl:value-of select="$src-id-sequence"/></src-id-sequence>
            <sort-and-group-by-what-alias><xsl:value-of select="$sort-and-group-by-what-alias-idrefs"/></sort-and-group-by-what-alias>
            <source-group-and-sort-pattern><xsl:copy-of select="$source-group-and-sort-pattern"/></source-group-and-sort-pattern>
            <!--<self-resolved><xsl:copy-of select="$self-resolved"/></self-resolved>-->
            <!--<sources-resolved><xsl:copy-of select="$sources-resolved"/></sources-resolved>-->
            <TAN-A-self-expanded><xsl:copy-of select="$self-expanded[tan:TAN-A]"/></TAN-A-self-expanded>
            <!--<src-ids><xsl:value-of select="$src-ids"/></src-ids>-->
            <!--<src-ids-from-sources><xsl:for-each select="$self-expanded/tan:TAN-T/@src">
                <xsl:value-of select=". || ' '"/>
            </xsl:for-each></src-ids-from-sources>-->
            <!--<self-head-expanded><xsl:copy-of select="$head"/></self-head-expanded>-->
            <!--<input-items><xsl:copy-of select="$input-items"/></input-items>-->
            <!--<input-pass-1><xsl:copy-of select="$input-pass-1"/></input-pass-1>-->
            <!--<input-pass-1b><xsl:copy-of select="$input-pass-1b"/></input-pass-1b>-->
            <!--<input-pass-1b-shallow><xsl:copy-of select="tan:shallow-copy($input-pass-1b, 3)"/></input-pass-1b-shallow>-->
            <!--<input-pass-1b-heads><xsl:copy-of select="$input-pass-1b/*/tan:head"/></input-pass-1b-heads>-->
            <!--<input-pass-2><xsl:copy-of select="$input-pass-2"/></input-pass-2>-->
            <!--<input-pass-3><xsl:copy-of select="$input-pass-3"/></input-pass-3>-->
            <!--<source-bibliography><xsl:copy-of select="$source-bibliography"/></source-bibliography>-->
            <!--<input-pass-4><xsl:copy-of select="$input-pass-4"/></input-pass-4>-->
            <!--<template-url-resolved><xsl:value-of select="$template-url-resolved"/></template-url-resolved>-->
            <!--<template-doc><xsl:copy-of select="$template-doc"/></template-doc>-->
            <!--<template-infused><xsl:copy-of select="$template-infused-with-revised-input"/></template-infused>-->
            <!--<infused-template-revised><xsl:copy-of select="$infused-template-revised"/></infused-template-revised>-->
            <!--<final-output><xsl:copy-of select="$final-output"/></final-output>-->
        </diagnostics>
    </xsl:template>

</xsl:stylesheet>
