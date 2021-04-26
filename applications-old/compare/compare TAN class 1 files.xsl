<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="true()"/>
    
    <xsl:include href="../get%20inclusions/core-for-TAN-output.xsl"/>
    <xsl:include href="../../functions/TAN-A-functions.xsl"/>
    <xsl:include href="../../functions/TAN-extra-functions.xsl"/>
    <xsl:include href="../get%20inclusions/save-files.xsl"/>
    <xsl:include href="../get%20inclusions/diff-and-collate-to-html.xsl"/>
    
    <xsl:import href="../../parameters/application-diff-parameters.xsl"/>
    <xsl:import href="../get%20inclusions/convert-TAN-to-HTML.xsl"/>

    <!-- This is a MIRU Stylesheet (MIRU = Main Input Resolved URIs) -->
    <!-- Primary (catalyzing) input: any XML file, including this one -->
    <!-- Secondary (main) input: resolved URIs to one or more class-1 files -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: for each group of files to be compared: (1) an XML file with the results
        of tan:diff() or tan:collate(), along with select statistical analyses; (2) an HTML file presenting
        the differences visually -->

    <!-- This stylesheet is useful only if the processed files are different versions of the same work in the same language. -->
    <!-- The XML output is a straightforward result of tan:diff() or tan:collate(), perhaps with statistical analysis prepended
    inside the root element. The HTML output has been designed to work with specific JavaScript and CSS files, and the HTML output
    will not render correctly unless you have set up dependencies correctly. See comments in code below. -->
    
    <!-- This application currently just scratches the surface of what is possible. Desiderata:
        1. Support a single TAN-A as the catalyst or MIRU provider, allowing <alias> to define the groups.
        2. Support MIRUs that point to non-TAN files, e.g., plain text, docx, xml.
        3. Support choice on whether Venn diagrams adjust the common area or not.
        4. Support choices of statistics to provide.
    -->

    <xsl:output indent="yes"/>
    
    <!-- PARAMETERS -->
    <!-- Other important parameters are to be found at /parameters/application-parameters.xsl. -->
    
    <xsl:param name="relative-uri-to-examples" select="'../../examples'"/>
    <xsl:param name="relative-uri-1" select="'../../../library-arithmeticus/aristotle'"/>
    <xsl:param name="relative-uri-2" select="'../../../library-arithmeticus/evagrius/cpg2439'"/>
    <xsl:param name="relative-uri-3" select="'../../../library-arithmeticus/bible'"/>
    <xsl:param name="relative-uri-4" select="'file:/e:/joel/google%20drive/clio%20commons/TAN%20library/clio'"/>
    <xsl:param name="relative-uri-5" select="'../../../library-arithmeticus/test'"/>
    
    <xsl:param name="main-input-relative-uri-directories" as="xs:string*" select="$relative-uri-5"/>
    
    <!-- In what directory are the class-1 files to be compared? Unless $main-input-resolved-uris has been given values directly, this parameter will be used to get a collection of all files in the directories chosen. -->
    <xsl:param name="main-input-resolved-uri-directories" as="xs:string*"
        select="
            for $i in $main-input-relative-uri-directories
            return
                string(resolve-uri($i, base-uri(/)))"
    />
    
    <!-- The input files are at what resolved URIs? Example: 'file:/c:/users/cjohnson/Downloads' -->
    <xsl:param name="main-input-resolved-uris" as="xs:string*">
        <xsl:for-each select="$main-input-resolved-uri-directories">
            <xsl:try select="uri-collection(.)">
                <xsl:catch>
                    <xsl:message select="'Unable to get a uri collection from ' || ."/>
                </xsl:catch>
            </xsl:try>
        </xsl:for-each>
    </xsl:param>
    
    <!-- For a main input resolved URI to be used, what pattern (regular expression, case-insensitive) must be matched? Any item in $main-input-resolved-uris not matching this pattern will be excluded. A null or empty string results in this parameter being ignored. -->
    <xsl:param name="mirus-must-match-regex" as="xs:string?" select="''"/>

    <!-- For a main input resolved URI to be used, what pattern (regular expression, case-insensitive) must NOT be matched? Any item in $main-input-resolved-uris matching this pattern will be excluded. A null or empty string results in this parameter being ignored. -->
    <xsl:param name="mirus-must-not-match-regex" as="xs:string?" select="'14616|1716|Montfaucon|gImage|abbyy'"/>
    
    <xsl:variable name="mirus-chosen"
        select="$main-input-resolved-uris[tan:filename-satisfies-regexes(., $mirus-must-match-regex, $mirus-must-not-match-regex)]"
    />
    
    <!-- Further restrictions on input -->
    
    <!-- What top-level divs, if any, should be excluded (regular expression)? If empty, this parameter will be ignored. -->
    <xsl:param name="exclude-top-level-divs-with-attr-n-matching-what" as="xs:string?" select="''"/>
    <xsl:variable name="check-top-level-div-ns" as="xs:boolean" select="string-length($exclude-top-level-divs-with-attr-n-matching-what) gt 0"/>
    
    <!-- In a given group of collations/diffs, should the TAN-T file be restricted to only top-level divs whose @ns match? -->
    <xsl:param name="restrict-to-matching-top-level-div-attr-ns" as="xs:boolean" select="true()"/>
    
    
    <!-- Adjustments to diff/collate input strings -->
    <!-- See also parameters/application-diff-parameters.xsl, shared with other
    applications that use tan:diff() and tan:collate(). -->
    
    <!-- Should texts be reduced to their string base when comparing them? E.g., should ö and o be treated as identical? Caution: if applied to Greek or another heavily accented language, any attempt to revert the diff results to the original could produce erratic results. -->
    <xsl:param name="ignore-character-component-differences" as="xs:boolean" select="false()"/>
    
    <!-- Should differences between the Greek grave and acute be ignored? -->
    <xsl:param name="ignore-greek-grave-acute-distinction" as="xs:boolean" select="false()"/>
    
    <!-- If Latin (body's @xml:lang = 'lat'), should batch replacement set 1 be used? -->
    <xsl:param name="apply-to-latin-batch-replacement-set-1" as="xs:boolean" select="true()"/>
    
    <!-- Should placement of marks in Syriac be ignored? -->
    <xsl:param name="ignore-syriac-dot-placement" as="xs:boolean" select="true()"/>
    
    <!-- If Syriac (body's @xml:lang = 'syr'), should batch replacement set 1 be used? -->
    <xsl:param name="apply-to-syriac-batch-replacement-set-1" as="xs:boolean" select="true()"/>
    
    <!-- Should <div> @ns be injected into the text? -->
    <xsl:param name="inject-attr-n" as="xs:boolean" select="false()"/>
    
    <!-- Collation/diff handling -->
    
    <!-- Should tan:collate() be allowed to re-sort the strings to take advantage of optimal matches? True produces better results, but could take longer than false. -->
    <xsl:param name="preoptimize-string-order" as="xs:boolean" select="true()"/>
    
    <!-- Should diffs be rendered word-for-word (true) or character-for-character? -->
    <xsl:param name="snap-to-word" as="xs:boolean" select="true()"/>
    
    <!-- Statistics -->
    
    <!-- What text differences should be ignored when compiling difference statistics? These must be supplied as a series of elements that group <c>s, e.g. <alias><c>'</c><c>"</c></alias> would, for statistical purposes, ignore differences merely of a single apostrophe and quotation mark. This affects only statistics. The difference would still be visible in the diff/collation. -->
    <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
    
    
    
    <!-- This application has many different parameters, and a slight change in one can radically alter the kind of results achieved. It is difficult
        to keep track of them all, so the following global variable collects the key items and prepares them for messaging.-->
    
    <xsl:variable name="global-notices" as="element()*">
        <input_selection>
            <message><xsl:value-of select="'Main input directory: ' || $main-input-resolved-uri-directories"/></message>
            <xsl:if test="string-length($mirus-must-match-regex) gt 0">
                <message><xsl:value-of select="'Restricted to files with filenames matching: ' || $mirus-must-match-regex"/></message>
            </xsl:if>
            <xsl:if test="string-length($mirus-must-not-match-regex) gt 0">
                <message><xsl:value-of select="'Avoiding any files with filenames matching: ' || $mirus-must-not-match-regex"/></message>
            </xsl:if>
            <message><xsl:value-of select="'Found ' || string(count($mirus-chosen)) || ' input files: ' || string-join($mirus-chosen, '; ')"/></message>
            <xsl:if test="$check-top-level-div-ns">
                <message><xsl:value-of select="'Excluding top-level divs whose @n values match ' || $exclude-top-level-divs-with-attr-n-matching-what"/></message>
            </xsl:if>
            <message><xsl:value-of select="'Exclude orphaned top-level divs? ' || $restrict-to-matching-top-level-div-attr-ns"/></message>
        </input_selection>
        <input_alteration>
            <xsl:if test="count($diff-and-collate-input-batch-replacements) gt 0">
                <message><xsl:value-of select="string(count($diff-and-collate-input-batch-replacements)) || ' batch replacements applied globally, in this order:'"/></message>
                <xsl:for-each select="$diff-and-collate-input-batch-replacements">
                    <message><xsl:value-of select="'Global replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                </xsl:for-each>
            </xsl:if>
            <message><xsl:value-of select="'Ignore case differences: ' || string($ignore-case-differences)"/></message>
            <message><xsl:value-of select="'Ignore combining marks: ' || string($ignore-combining-marks)"/></message>
            <message><xsl:value-of select="'Ignore character component differences: ' || string($ignore-character-component-differences)"/></message>
            <message><xsl:value-of select="'Ignore punctuation differences: ' || string($ignore-punctuation-differences)"/></message>
            <xsl:if test="$main-input-files-expanded/tan:TAN-T/tan:body/@xml:lang = 'grc'">
                <message><xsl:value-of select="'Ignore differences in Greek between grave and acute accents: ' || string($ignore-greek-grave-acute-distinction)"/></message>
            </xsl:if>
            <xsl:if test="$main-input-files-expanded/tan:TAN-T/tan:body/@xml:lang = 'lat'">
                <xsl:if test="$apply-to-latin-batch-replacement-set-1">
                    <message><xsl:value-of select="'Applying the following batch replacements to all Latin text: '"/></message>
                    <xsl:for-each select="$latin-batch-replacements-1">
                        <message><xsl:value-of select="'Latin replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$main-input-files-expanded/tan:TAN-T/tan:body/@xml:lang = 'syr'">
                <message><xsl:value-of select="'Ignore differences in placement of Syriac marks: ' || string($ignore-syriac-dot-placement)"/></message>
                <xsl:if test="$apply-to-syriac-batch-replacement-set-1">
                    <message><xsl:value-of select="'Applying the following batch replacements to all Syriac text: '"/></message>
                    <xsl:for-each select="$syriac-batch-replacements-1">
                        <message><xsl:value-of select="'Latin replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$inject-attr-n">
                <message>Injecting @n values into the input before making comparisons.</message>
            </xsl:if>
        </input_alteration>
        <collation_handling>
            <message><xsl:value-of select="'Preoptimize string order for tan:collate()? ' || string($preoptimize-string-order)"/></message>
            <message><xsl:value-of select="'Treat differences word-for-word (not character-for-character)? ' || string($snap-to-word)"/></message>
        </collation_handling>
        <statistics>
            <xsl:if test="count($unimportant-change-character-aliases) gt 0">
                <message><xsl:value-of select="string(count($unimportant-change-character-aliases)) || ' groups of changes will be ignored for the sake of statistical analysis.'"/></message>
                <xsl:for-each select="$unimportant-change-character-aliases">
                    <message><xsl:value-of select="'Character alias ' || string(position()) || ': ' || string-join('[' || * || ']', ' ')"/></message>
                </xsl:for-each>
            </xsl:if>
        </statistics>
        <output>
            <message><xsl:value-of select="'Collate/diff results in the HTML file are replaced with their original form (e.g., ignored punctuation is restored, capitalization is restored): ' || string($replace-diff-results-with-pre-alteration-forms)"/></message>
        </output>
    </xsl:variable>
    
    
    
    
    
    <!-- STYLESHEET PARAMETERS -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:compare-class-1-files'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="stylesheet-name" select="'Application to compare class 1 files'"/>
    <xsl:param name="change-message" select="'Compared class 1 files.'"/>
    <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-10-06">Revise process that reinfuses a class 1 file with a diff/collate into a standard extra TAN function.</comment>
        </to-do>
    </xsl:param>
    
    
    <!-- Beginning of main input -->
    
    <xsl:variable name="main-input-files" select="tan:open-file($mirus-chosen)"/>
    
    <xsl:variable name="main-input-class-1-files" select="$main-input-files[tei:TEI or tan:TAN-T]"/>
    
    <xsl:variable name="main-input-files-resolved" as="document-node()*"
        select="
            for $i in $main-input-class-1-files
            return
                tan:resolve-doc($i, true(), ())"
    />
    
    <xsl:variable name="main-input-files-expanded" as="document-node()*"
        select="
            for $i in $main-input-files-resolved
            return
                tan:expand-doc($i, 'terse', false())"
    />
    
    <!-- GROUPING KEYS -->
    
    <!-- The mode core-expansion-ad-hoc-pre-pass mode is used to build grouping and sort keys. If you wish to modify how groups are built,
    or sorted, you can simply add rules to the template mode build-comparison-[grouping/sort]-key -->
    <xsl:template match="/*" mode="core-expansion-ad-hoc-pre-pass">
        <xsl:variable name="keys-and-label" as="element()*">
            <xsl:apply-templates select="." mode="build-keys-and-label"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="grouping-key" select="string-join($keys-and-label/self::tan:grouping-key, ' ')"/>
            <xsl:attribute name="sort-key" select="string-join($keys-and-label/self::tan:sort-key, ' ')"/>
            <xsl:attribute name="label" select="replace(string-join($keys-and-label/self::tan:label, '_'), '[\s.]', '_')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template
        match="
            tan:body/tan:div[$check-top-level-div-ns and
                matches(@n, $exclude-top-level-divs-with-attr-n-matching-what)]"
        mode="core-expansion-ad-hoc-pre-pass"/>
    
    <xsl:template match="tan:div" mode="core-expansion-ad-hoc-pre-pass">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$inject-attr-n">
                <xsl:value-of select="@n || ' '"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- by default, nothing goes into keys or a label unless specified -->
    <xsl:template match="* | text() | comment() | processing-instruction()" mode="build-keys-and-label">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <!-- A diff/collation of texts that do not share the same language makes no sense, so the @xml:lang value should be part of the key. -->
    <xsl:template match="*:body" mode="build-keys-and-label">
        <grouping-key><xsl:value-of select="@xml:lang"/></grouping-key>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <!-- Default sort and label is by filename -->
    <xsl:template match="/*" mode="build-keys-and-label">
        <xsl:variable name="this-filename" select="tan:cfn(@xml:base)"/>
        <sort-key><xsl:value-of select="$this-filename"/></sort-key>
        <label><xsl:value-of select="replace($this-filename, '%20', ' ')"/></label>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    
    <!-- This builds a series of XML documents with the diffs and collations, plus simple metadata on each file -->
    <xsl:variable name="file-groups-diffed-and-collated" as="document-node()*">
        <xsl:for-each-group select="$main-input-files-expanded" group-by="*/@grouping-key">
            <xsl:variable name="this-group-pos" select="position()"/>
            <xsl:variable name="this-group-name" select="current-grouping-key()"/>
            <xsl:variable name="this-group-count" select="count(current-group())"/>
            <xsl:variable name="these-group-labels" select="current-group()/*/@label"/>
            <xsl:variable name="this-group" as="document-node()+">
                <xsl:for-each select="current-group()">
                    <xsl:sort select="*/@sort-key"/>
                    <xsl:sequence select="."/>
                </xsl:for-each>
            </xsl:variable>
            
            <!--<xsl:variable name="duplicate-top-level-div-attr-ns"
                select="
                    if ($restrict-to-matching-top-level-div-attr-ns) then
                        tan:duplicate-values($this-group/*/tan:body/tan:div/@n)
                    else
                        ()"
            />-->
            <xsl:variable name="duplicate-top-level-div-attr-ns" as="xs:string*">
                <xsl:if test="$restrict-to-matching-top-level-div-attr-ns">
                    <xsl:for-each-group select="$this-group/*/tan:body/tan:div/@n" group-by=".">
                        <xsl:if test="count(current-group()) ge $this-group-count">
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:if>
                    </xsl:for-each-group> 
                </xsl:if>
            </xsl:variable>
            
            <xsl:variable name="these-langs" select="distinct-values($this-group/tan:TAN-T/tan:body/@xml:lang)"/>
            <xsl:variable name="extra-batch-replacements" as="element()*">
                <xsl:if test="$these-langs = 'lat' and $apply-to-latin-batch-replacement-set-1">
                    <xsl:sequence select="$latin-batch-replacements-1"/>
                </xsl:if>
                <xsl:if test="$these-langs = 'syr' and $apply-to-syriac-batch-replacement-set-1">
                    <xsl:sequence select="$syriac-batch-replacements-1"/>
                </xsl:if>
            </xsl:variable>            
            
            <xsl:variable name="these-raw-texts"
                select="
                    for $i in $this-group
                    return
                        if (exists($duplicate-top-level-div-attr-ns)) then
                            tan:text-join($i/*/tan:body/tan:div[@n = $duplicate-top-level-div-attr-ns])
                        else
                            tan:text-join($i/*/tan:body)"
            />
            <xsl:variable name="these-texts-normalized-1"
                select="
                    if (count(($diff-and-collate-input-batch-replacements, $extra-batch-replacements)) gt 0) then
                        (for $i in $these-raw-texts
                        return
                            tan:batch-replace($i, ($diff-and-collate-input-batch-replacements, $extra-batch-replacements)))
                    else
                        $these-raw-texts"
            />
            
            <xsl:variable name="these-texts-normalized-2" as="xs:string*"
                select="
                    if ($ignore-character-component-differences) then
                        (for $i in $these-texts-normalized-1
                        return
                            tan:string-base($i))
                    else
                        $these-texts-normalized-1"
            />

            <xsl:variable name="these-texts-normalized-3" as="xs:string*">
                <xsl:choose>
                    <xsl:when test="$these-langs = 'grc' and $ignore-greek-grave-acute-distinction">
                        <xsl:sequence
                            select="
                                for $i in $these-texts-normalized-2
                                return
                                    tan:greek-graves-to-acutes($i)"
                        />
                    </xsl:when>
                    <xsl:when test="$these-langs = 'syr' and $ignore-syriac-dot-placement">
                        <xsl:sequence
                            select="
                                for $i in $these-texts-normalized-2
                                return
                                    tan:syriac-marks-to-word-end($i)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$these-texts-normalized-2"></xsl:sequence>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!--<xsl:variable name="these-texts-normalized-3" as="xs:string*"
                select="
                    if ($ignore-greek-grave-acute-distinction) then
                        (for $i in $these-texts-normalized-2
                        return
                            tan:greek-graves-to-acutes($i))
                    else
                        $these-texts-normalized-2"
            />-->

            <xsl:variable name="finalized-texts-to-compare" as="xs:string*"
                select="
                    if ($ignore-case-differences) then
                        (for $i in $these-texts-normalized-3
                        return
                            lower-case($i))
                    else
                        $these-texts-normalized-3"
            />
            
            <xsl:variable name="these-labels"
                select="
                    for $i in $this-group
                    return
                        ($i/*/@label, '')[1]"
            />
            <xsl:variable name="these-duplicate-labels" select="tan:duplicate-values($these-labels)"/>
            <xsl:variable name="these-labels-revised" as="xs:string*">
                <xsl:for-each select="$these-labels">
                    <xsl:variable name="this-pos" select="position()"/>
                    <xsl:choose>
                        <xsl:when test=". = ('', $these-duplicate-labels)">
                            <xsl:value-of select="string-join((., string($this-pos)), ' ')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>


            <!-- global variable's messaging, output -->
            <xsl:for-each select="$finalized-texts-to-compare">
                <xsl:variable name="this-pos" select="position()"/>
                <xsl:choose>
                    <xsl:when test="string-length(.) lt 1">
                        <xsl:message
                            select="$this-group[$this-pos]/*/@xml:base || ' is a zero-length string.'"
                        />
                    </xsl:when>
                    <xsl:when test="not(matches(., '\w'))">
                        <xsl:message
                            select="$this-group[$this-pos]/*/@xml:base || ' has no letters.'"
                        />
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>

            <xsl:choose>
                <!-- Ignore groups beyond the threshold -->
                <xsl:when test="count($this-group) lt 2">
                    <xsl:message
                        select="'Ignoring ' || $this-group/*/@xml:base || ' because it has no pair.'"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        some $i in $finalized-texts-to-compare
                            satisfies ($i = ('', ()))">
                    <xsl:message
                        select="'Ignoring entire set of texts because at least one of them, after normalization, results in a zero-length string. Check: ' || string-join($this-group/*/@xml:base, ' ')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:document>
                        <group cgk="{current-grouping-key()}" count="{count($this-group)}"
                            _target-format="xml-indent"
                            _target-uri="{$target-output-directory-resolved || 'diff-' || current-grouping-key() || '-' || $today-iso || '.xml'}">
                            <group-name><xsl:value-of select="$this-group-name"/></group-name>
                            <group-label><xsl:value-of select="distinct-values($these-group-labels)"/></group-label>
                            <xsl:for-each select="$this-group">
                                <xsl:variable name="this-pos" select="position()"/>
                                <xsl:variable name="this-raw-text" select="$these-raw-texts[$this-pos]"/>
                                <xsl:variable name="this-text-finalized"
                                    select="$finalized-texts-to-compare[$this-pos]"/>
                                <xsl:variable name="this-id-ref"
                                    select="$these-labels-revised[$this-pos]"/>
                                <file orig-length="{string-length($this-raw-text)}"
                                    length="{string-length($this-text-finalized)}"
                                    uri="{*/@xml:base}" ref="{$this-id-ref}">
                                    <!-- If there is a discrepancy between the input text and the output, then the original text is kept,
                                        so that at a later stage, after statistics have been compiled, the <diff> output can be massaged
                                        for HTML display. -->
                                    <!-- I don't think we need this. -->
                                    <!--<xsl:if test="not($this-text-finalized eq $this-raw-text)">
                                        <orig-text><xsl:value-of select="$this-raw-text"/></orig-text>
                                    </xsl:if>-->
                                </file>
                            </xsl:for-each>
                            

                            <xsl:choose>
                                
                                <xsl:when test="count($finalized-texts-to-compare) eq 2">
                                    <xsl:copy-of
                                        select="tan:adjust-diff(tan:diff($finalized-texts-to-compare[1], $finalized-texts-to-compare[2], $snap-to-word))"
                                    />
                                </xsl:when>
                                
                                <xsl:otherwise>
                                    <xsl:copy-of
                                        select="tan:collate($finalized-texts-to-compare, $these-labels-revised, $preoptimize-string-order, true(), true(), $snap-to-word)"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </group>
                    </xsl:document>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:template match="/*" mode="isolate-leaf-divs">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="tan:body" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:body" mode="isolate-leaf-divs">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="tan:div" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:body/tan:div" priority="1" mode="isolate-leaf-divs">
        <xsl:param name="top-level-n-filter" tunnel="yes" as="xs:string*"/>
        <xsl:variable name="use-me" select="(not(exists($top-level-n-filter)) or @n = $top-level-n-filter)"/>
        <xsl:choose>
            <xsl:when test="$use-me and not(exists(tan:div))">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:value-of select="text()"/>
                    <xsl:apply-templates select="tan:tok | tan:non-tok" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$use-me">
                <xsl:apply-templates select="tan:div" mode="#current"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:tok | tan:non-tok" mode="isolate-leaf-divs">
        <xsl:value-of select="."/>
    </xsl:template>
    
    
    <!-- Next, build a statistical profile. This battery of routines is in TAN's extra functions. -->
    
    <xsl:variable name="file-groups-with-stats" as="document-node()*">
        <xsl:apply-templates select="$file-groups-diffed-and-collated" mode="infuse-diff-and-collate-stats">
            <xsl:with-param name="unimportant-change-character-aliases" as="element()*"
                select="$unimportant-change-character-aliases" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    
    <!-- Infusion of diff / collation in first expanded TAN-T file -->
    <!-- We also insert the global notices, and replace the diff or collation, if required. -->
    
    <xsl:variable name="output-containers-prepped" as="document-node()*">
        <xsl:apply-templates select="$file-groups-with-stats"
            mode="infuse-class-1-with-diff-or-collation"/>
    </xsl:variable>
    
    <xsl:template match="tan:group" mode="infuse-class-1-with-diff-or-collation">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <notices>
                <xsl:copy-of select="$global-notices"/>
            </notices>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:group/tan:diff | tan:group/tan:collation" mode="infuse-class-1-with-diff-or-collation">
        <!-- group/stats/witness sorts them according to label order whereas group/collation/witness (if a collation) puts the
        least divergent witness at the top. We presume the former is the one of interest, and that because many labels have 
        numbers that help them sort in chronological order, that the last is the most interesting. -->
        <xsl:variable name="primary-witness"
            select="
                if (self::tan:diff) then
                    ../tan:stats/tan:witness[1]
                else
                    ../tan:stats/tan:witness[last()]"
        />
        <xsl:variable name="diff-b-class-1-base-uri" select="../tan:stats/tan:witness[2]/tan:uri"/>
        <xsl:variable name="primary-class-1-base-uri" select="$primary-witness/tan:uri"/>
        
        <xsl:variable name="primary-class-1-idref" select="$primary-witness/@ref"/>
        
        <xsl:variable name="primary-class-1-doc" select="$main-input-files-expanded[*/@xml:base = $primary-class-1-base-uri]"/>
        <xsl:variable name="diff-b-class-1-doc" select="$main-input-files-expanded[*/@xml:base = $diff-b-class-1-base-uri]"/>
        
        <!--<xsl:variable name="first-class-1-doc-analyzed" select="tan:stamp-class-1-tree-with-text-data($first-class-1-doc)"/>-->
        <xsl:variable name="primary-class-1-doc-analyzed" select="tan:stamp-class-1-tree-with-text-data($primary-class-1-doc)"/>
        
        <xsl:variable name="split-collation-where" select="key('elements-with-attrs-named', '_pos', $primary-class-1-doc-analyzed/*/tan:body)//tan:div[not(tan:div)]"/>
        <xsl:variable name="split-count" select="count($split-collation-where)"/>

        <xsl:variable name="this-diff-or-collation-revised" as="element()">
            <xsl:choose>
                <xsl:when test="$replace-diff-results-with-pre-alteration-forms and self::tan:diff">
                    <xsl:copy-of
                        select="tan:stamp-diff-with-text-data(tan:replace-diff(
                        string-join($primary-class-1-doc/tan:TAN-T/tan:body//tan:div[not(tan:div)]/text()),
                        string-join($diff-b-class-1-doc/tan:TAN-T/tan:body//tan:div[not(tan:div)]/text()), 
                        .))"/>
                </xsl:when>
                
                <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                    <xsl:sequence
                        select="
                            tan:replace-collation(string-join($primary-class-1-doc/tan:TAN-T/tan:body//tan:div[not(tan:div)]/text()), 
                            $primary-class-1-idref, .)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="leaf-divs-infused" as="element()*">
            <xsl:choose>
                <xsl:when test="self::tan:diff">
                    <xsl:iterate select="$split-collation-where">
                        <xsl:param name="diff-so-far" as="element()" select="$this-diff-or-collation-revised"/>
                        <xsl:variable name="this-string-last-pos"
                            select="xs:integer(@_pos) + xs:integer(@_len) - 1"/>
                        <xsl:variable name="first-diff-element-not-of-interest"
                            select="$diff-so-far/(tan:a | tan:common)[xs:integer(@_pos) gt $this-string-last-pos][1]"/>
                        <xsl:variable name="diff-elements-not-of-interest"
                            select="$first-diff-element-not-of-interest | $first-diff-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="diff-elements-of-interest"
                            select="$diff-so-far/(* except $diff-elements-not-of-interest)"/>
                        <xsl:variable name="last-diff-element-of-interest-with-this-witness"
                            select="$diff-elements-of-interest[self::tan:a or self::tan:common][last()]"/>
                        <xsl:variable name="last-deoiwtw-pos"
                            select="xs:integer($last-diff-element-of-interest-with-this-witness/@_pos)"/>
                        <xsl:variable name="last-deoiwtw-length"
                            select="xs:integer($last-diff-element-of-interest-with-this-witness/@_len)"/>
                        <xsl:variable name="amount-needed"
                            select="$this-string-last-pos - $last-deoiwtw-pos + 1"/>
                        <xsl:variable name="fragment-to-keep" as="element()*">
                            <xsl:if test="exists($last-diff-element-of-interest-with-this-witness)">
                                <xsl:element name="{name($last-diff-element-of-interest-with-this-witness)}">
                                    <xsl:value-of
                                        select="substring($last-diff-element-of-interest-with-this-witness, 1, ($amount-needed, 0)[1])"
                                    />
                                </xsl:element>
                                <!-- If what follows is simply a <b> and the whole of the last diff element is desired, then that
                                <b> should be kept as well. We don't worry about cases where the next sibling is an <a> or <common>
                                because that is already accounted for by $first-diff-element-not-of-interest. -->
                                <xsl:if test="not($last-deoiwtw-length gt $amount-needed)">
                                    <xsl:copy-of
                                        select="$last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:b"
                                    />
                                </xsl:if>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="fragment-to-push-to-next-iteration" as="element()*">
                            <xsl:if
                                test="($last-deoiwtw-length gt $amount-needed) and exists($last-diff-element-of-interest-with-this-witness)">
                                <xsl:element name="{name($last-diff-element-of-interest-with-this-witness)}">
                                    <xsl:attribute name="_len"
                                        select="$last-deoiwtw-length - $amount-needed"/>
                                    <xsl:attribute name="_pos" select="$last-deoiwtw-pos + $amount-needed"/>
                                    
                                    <xsl:value-of
                                        select="substring($last-diff-element-of-interest-with-this-witness, ($amount-needed, 0)[1] + 1)"
                                    />
                                </xsl:element>
                                <!-- If only part of the last element of interest is kept, then if the next item is a <b>, it
                                should be pushed to the next iteration. -->
                                <xsl:copy-of
                                    select="$last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:b"
                                />
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="next-diff" as="element()">
                            <diff>
                                <xsl:copy-of select="$fragment-to-push-to-next-iteration"/>
                                <xsl:copy-of select="$diff-elements-not-of-interest"/>
                            </diff>
                        </xsl:variable>
                        
                        <xsl:variable name="diagnostics-on" select="not(exists($amount-needed))"/>
                        <xsl:if test="$diagnostics-on">
                            <xsl:message select="'Iterating over ', tan:shallow-copy(.)"/>
                            <xsl:message select="'This string, last pos:', $this-string-last-pos"/>
                            <xsl:message select="'First diff element not of interest: ', $first-diff-element-not-of-interest"/>
                            <xsl:message select="'Diff elements of interest: ', $diff-elements-of-interest"/>
                            <xsl:message select="'Last diff element of interest with this witness: ', $last-diff-element-of-interest-with-this-witness"/>
                            <xsl:message select="'Last diff element of interest with this witness pos: ', $last-deoiwtw-pos"/>
                            <xsl:message select="'Last diff element of interest with this witness length: ', $last-deoiwtw-length"/>
                            <xsl:message select="'Amount needed:', $amount-needed"/>
                            <xsl:message select="'Fragment to keep: ', $fragment-to-keep"/>
                            <xsl:message select="'Fragment to push to next iteration: ', $fragment-to-push-to-next-iteration"/>
                        </xsl:if>
                        
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node() except (text() | tei:*)"/>
                            <xsl:if test="not(exists($last-diff-element-of-interest-with-this-witness))">
                                <xsl:for-each select="$diff-elements-of-interest">
                                    <xsl:copy>
                                        <xsl:value-of select="."/>
                                    </xsl:copy>
                                </xsl:for-each>
                            </xsl:if>
                            <!-- $last-diff-element-of-interest-with-this-witness/preceding-sibling::*, $fragment-to-keep,
                                $last-diff-element-of-interest-with-this-witness/(following-sibling::* except $diff-elements-not-of-interest) -->
                            <xsl:for-each
                                select="
                                    $last-diff-element-of-interest-with-this-witness/preceding-sibling::*, $fragment-to-keep">
                                <xsl:copy>
                                    <xsl:value-of select="."/>
                                </xsl:copy>
                            </xsl:for-each>
                        </xsl:copy>
                        
                        <xsl:choose>
                            <xsl:when test="not(exists($next-diff))">
                                <xsl:break/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:next-iteration>
                                    <xsl:with-param name="diff-so-far" select="$next-diff"/>
                                </xsl:next-iteration>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        
                    </xsl:iterate>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:iterate select="$split-collation-where">
                        <xsl:param name="collation-so-far" as="element()" select="$this-diff-or-collation-revised"/>
                        <xsl:variable name="this-string-last-pos" select="xs:integer(@_pos) + xs:integer(@_len) - 1"/>
                        <xsl:variable name="first-collation-element-not-of-interest" select="$collation-so-far/*[tan:wit[@ref = $primary-class-1-idref][xs:integer(@pos) gt $this-string-last-pos]][1]"/>
                        <xsl:variable name="collation-elements-not-of-interest" select="$first-collation-element-not-of-interest | $first-collation-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="collation-elements-of-interest" select="$collation-so-far/(* except $collation-elements-not-of-interest)"/>
                        <xsl:variable name="last-collation-element-of-interest-with-this-witness" select="$collation-elements-of-interest[tan:wit[@ref = $primary-class-1-idref]][last()]"/>
                        <xsl:variable name="last-ceoiwtw-pos" select="xs:integer($last-collation-element-of-interest-with-this-witness/tan:wit[@ref = $primary-class-1-idref]/@pos)"/>
                        <xsl:variable name="last-ceoiwtw-length" select="string-length($last-collation-element-of-interest-with-this-witness/tan:txt)"/>
                        <xsl:variable name="amount-needed" select="$this-string-last-pos - $last-ceoiwtw-pos + 1"/>
                        <xsl:variable name="fragment-to-keep" as="element()*">
                            <xsl:if test="exists($last-collation-element-of-interest-with-this-witness)">
                                <xsl:element
                                    name="{name($last-collation-element-of-interest-with-this-witness)}">
                                    <txt>
                                        <xsl:value-of
                                            select="substring($last-collation-element-of-interest-with-this-witness, 1, $amount-needed)"
                                        />
                                    </txt>
                                    <xsl:copy-of
                                        select="$last-collation-element-of-interest-with-this-witness/tan:wit"
                                    />
                                </xsl:element>
                                <xsl:if test="not($last-ceoiwtw-length gt $amount-needed)">
                                    <xsl:copy-of select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"/>
                                </xsl:if>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="fragment-to-push-to-next-iteration" as="element()*">
                            <xsl:if test="$last-ceoiwtw-length gt $amount-needed and exists($last-collation-element-of-interest-with-this-witness)">
                                <xsl:element name="{name($last-collation-element-of-interest-with-this-witness)}">
                                    <txt>
                                        <xsl:value-of select="substring($last-collation-element-of-interest-with-this-witness, $amount-needed + 1)"/>
                                    </txt>
                                    <xsl:for-each select="$last-collation-element-of-interest-with-this-witness/tan:wit">
                                        <xsl:copy>
                                            <xsl:copy-of select="@ref"/>
                                            <xsl:attribute name="pos"
                                                select="xs:integer(@pos) + $amount-needed"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:element>
                                <xsl:copy-of select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"/>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="next-collation" as="element()">
                            <collation>
                                <xsl:copy-of select="$fragment-to-push-to-next-iteration"/>
                                <xsl:copy-of select="$collation-elements-not-of-interest"/>
                            </collation>
                        </xsl:variable>
                        
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node() except (text() | tei:*)"/>
                            <xsl:copy-of select="$last-collation-element-of-interest-with-this-witness/preceding-sibling::*[not(self::tan:witness)]"/>
                            <xsl:copy-of select="$fragment-to-keep"/>
                            <!--<xsl:copy-of select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"/>-->
                        </xsl:copy>
                        
                        <xsl:choose>
                            <xsl:when test="not(exists($next-collation))">
                                <xsl:break/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:next-iteration>
                                    <xsl:with-param name="collation-so-far" select="$next-collation"/>
                                </xsl:next-iteration>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        
                    </xsl:iterate>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode infuse-class-1-with-diff-or-collation'"/>
            <xsl:message select="'First class 1 base uri: ' || $primary-class-1-base-uri"/>
            <xsl:message select="'Split diff or collation where? ' || string-join($split-collation-where/@_pos, ', ')"/>
            <xsl:message select="'First infused leaf div: ', $leaf-divs-infused[1]"/>
        </xsl:if>
        
        <xsl:copy>
            <xsl:copy-of select="tan:witness"/>
            <!--<test25>
                <first-class-1-analyzed><xsl:copy-of select="$primary-class-1-doc-analyzed"/></first-class-1-analyzed>
                <primary-class-1-analyzed><xsl:copy-of select="$primary-class-1-doc-analyzed"/></primary-class-1-analyzed>
                <this-diff-or-collation-revised><xsl:copy-of select="$this-diff-or-collation-revised"/></this-diff-or-collation-revised>
                <leaf-divs-infused><xsl:copy-of select="$leaf-divs-infused"/></leaf-divs-infused>
            </test25>-->
            <xsl:apply-templates select="$primary-class-1-doc/*/tan:body/tan:div"
                mode="infuse-class-1-with-diff-or-collation">
                <xsl:with-param name="element-replacements" tunnel="yes" select="$leaf-divs-infused"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="tan:div" mode="infuse-class-1-with-diff-or-collation">
        <xsl:param name="element-replacements" tunnel="yes" as="element()*"/>
        <xsl:variable name="this-q" select="@q"/>
        <xsl:variable name="this-substitute" select="$element-replacements[@q = $this-q]"/>
        <xsl:choose>
            <xsl:when test="exists($this-substitute)">
                <xsl:copy-of select="$this-substitute"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@* except @q"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- HTML OUTPUT -->
    
    <!-- Much of the following template mode has been moved to an inclusion -->
    <xsl:variable name="output-as-html" as="document-node()*">
        <xsl:apply-templates select="$output-containers-prepped" mode="diff-and-collate-to-html">
            <xsl:with-param name="include-text-change-warning" tunnel="yes"
                select="$replace-diff-results-with-pre-alteration-forms"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:template match="/*" mode="diff-and-collate-to-html">
        <xsl:variable name="this-title" as="xs:string*">
            <xsl:value-of select="tan:text-to-html-for-compare-app(string-join((tan:group-name, tan:group-label), ' '))"/>
        </xsl:variable>
        <xsl:variable name="this-subtitle" as="xs:string*">
            <xsl:text>TAN-driven analysis of </xsl:text>
            <xsl:value-of
                select="replace((tan:stats/*/tan:uri)[last()], '.+/([^/]+)\.\w+$', '$1') || ', a comparison of ' || string(count(tan:stats/tan:witness)) || ' files'"
            />
        </xsl:variable>
        <xsl:variable name="this-target-uri" select="replace(@_target-uri, '\w+$', 'html')"/>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="_target-format">xhtml-noindent</xsl:attribute>
            <xsl:attribute name="_target-uri" select="$this-target-uri"/>
            <head>
                <title>
                    <xsl:value-of select="string-join(($this-title, $this-subtitle, ' '))"/>
                </title>
                <!-- TAN css attend to some basic style issues common to TAN converted to HTML. -->
                <link rel="stylesheet"
                    href="{tan:uri-relative-to($resolved-uri-to-diff-css, $this-target-uri)}"
                    type="text/css">
                    <xsl:comment/>
                </link>
                <!-- The TAN JavaScript code uses jQuery. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-jquery, $this-target-uri)}"><!--  --></script>
                <!-- The d3js library is required for use of the Venn JavaScript library -->
                <script src="https://d3js.org/d3.v5.min.js"><!--  --></script>
                <!-- The Venn JavaScript library: https://github.com/benfred/venn.js/ -->
                <script src="{$resolved-uri-to-venn-js}"><!--  --></script>
            </head>
            <body>
                <div class="title">
                    <xsl:value-of select="$this-title"/>
                </div>
                <h1>
                    <xsl:value-of select="$this-subtitle"/>
                </h1>
                <div class="timedate">
                    <xsl:value-of
                        select="'Comparison generated ' || format-dateTime(current-dateTime(), '[MNn] [D], [Y], [h]:[m01] [PN]')"
                    />
                </div>
                <xsl:apply-templates select="* except (tan:group-label | tan:group-name)" mode="#current">
                    <xsl:with-param name="last-wit-idref" select="tan:stats/tan:witness[last()]/@ref"
                        tunnel="yes"/>
                </xsl:apply-templates>
                <!-- TAN JavaScript comes at the end, to ensure the DOM is loaded. The file supports manipulation of the sources and their appearance. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-diff-js, $this-target-uri)}"><!--  --></script>
                <!-- The TAN JavaScript library provides some generic functionality across all TAN HTML output -->
                <script src="{tan:uri-relative-to($resolved-uri-to-TAN-js, $this-target-uri)}"><!--  --></script>
            </body>
        </html>
    </xsl:template>
    
    
    <xsl:variable name="resolved-uri-to-diff-css"
        select="($target-output-directory-resolved || 'css/diff.css')"/>
    <xsl:variable name="resolved-uri-to-TAN-js"
        select="($target-output-directory-resolved || 'js/tan2020.js')"/>
    <xsl:variable name="resolved-uri-to-diff-js"
        select="($target-output-directory-resolved || 'js/diff.js')"/>
    <xsl:variable name="resolved-uri-to-jquery"
        select="($target-output-directory-resolved || 'js/jquery.js')"/>
    <xsl:variable name="resolved-uri-to-venn-js"
        select="($target-output-directory-resolved || 'js/venn.js/venn.js')"/>
    

    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Output diagnostics on for ' || static-base-uri()"/>
        <diagnostics>
            <!--<reconcile-diff-testing>
                <xsl:variable name="str-a" select="'Come on, whats the difference?'"/>
                <xsl:variable name="str-b" select="'come on what is the difference'"/>
                <xsl:variable name="str-c" select="'come on... What the difference is?'"/>
                <xsl:variable name="str-a-adj" select="lower-case(replace($str-a, '[\p{P}]', '$0$0'))"/>
                <xsl:variable name="str-b-adj" select="lower-case(replace($str-b, '[\p{P}]', '$0$0'))"/>
                <xsl:variable name="str-c-adj" select="lower-case(replace($str-c, '[\p{P}]', '$0$0'))"/>
                <xsl:variable name="adjusted-diff" select="tan:diff($str-a-adj, $str-b-adj, false())"/>
                <xsl:variable name="unadjusted-diff" select="tan:replace-diff($str-a, $str-b, $adjusted-diff)"/>
                <xsl:variable name="adjusted-collate" select="tan:collate(($str-a-adj, $str-b-adj, $str-c-adj), (), true())"/>
                <xsl:variable name="top-collation-witness" select="$adjusted-collate/tan:witness[1]/@id"/>
                <xsl:variable name="original-text"
                    select="
                        if ($top-collation-witness eq '1') then
                            $str-a
                        else
                            if ($top-collation-witness eq '2') then
                                $str-b
                            else
                                $str-c"
                />
                <xsl:variable name="reverted-collation" select="tan:replace-collation($original-text, $top-collation-witness, $adjusted-collate)"/>
                <str-a><xsl:value-of select="$str-a"/></str-a>
                <str-b><xsl:value-of select="$str-b"/></str-b>
                <str-c><xsl:value-of select="$str-c"/></str-c>
                <str-a-adj><xsl:value-of select="$str-a-adj"/></str-a-adj>
                <str-b-adj><xsl:value-of select="$str-b-adj"/></str-b-adj>
                <str-c-adj><xsl:value-of select="$str-c-adj"/></str-c-adj>
                <!-\-<adjusted-diff><xsl:copy-of select="$adjusted-diff"/></adjusted-diff>-\->
                <!-\-<unadjusted-diff><xsl:copy-of select="$unadjusted-diff"/></unadjusted-diff>-\->
                <adjusted-collate><xsl:copy-of select="$adjusted-collate"/></adjusted-collate>
                <reverted-collation><xsl:copy-of select="$reverted-collation"/></reverted-collation>
            </reconcile-diff-testing>-->
            <!--<expanded-class-1-replace>
                <xsl:variable name="this-expanded-file" select="$main-input-files-expanded[1]"/>
                <xsl:variable name="this-text" select="string-join($this-expanded-file/tan:TAN-T/tan:body//tan:div[not(tan:div)]/(text() | tan:tok | tan:non-tok))"/>
                <xsl:variable name="this-new-text" select="replace($this-text, '[οι]', '')"/>
                <replace-output><xsl:copy-of select="tan:replace-expanded-class-1-body($this-expanded-file, $this-new-text)"/></replace-output>
            </expanded-class-1-replace>-->
            <!--<grave-test><xsl:copy-of select="tan:greek-graves-to-acutes('ἱκανόὸν τήὴν πρόὸς τούὺς')"/></grave-test>-->
            <!--<main-input-resolved-uris count="{count($main-input-resolved-uris)}"><xsl:value-of select="$main-input-resolved-uris"/></main-input-resolved-uris>-->
            <!--<MIRUs-chosen count="{count($mirus-chosen)}"><xsl:value-of select="$mirus-chosen"/></MIRUs-chosen>-->
            <!--<input-class-1-files count="{count($main-input-class-1-files)}"/>-->
            <!--<input-expanded-with-grouping-keys><xsl:copy-of select="tan:shallow-copy($main-input-files-expanded, 2)"/></input-expanded-with-grouping-keys>-->
            <!--<output-dir><xsl:value-of select="$target-output-directory-resolved"/></output-dir>-->
            <!--<main-input-files-resolved><xsl:copy-of select="$main-input-files-resolved"/></main-input-files-resolved>-->
            <!--<main-input-files-expanded><xsl:copy-of select="$main-input-files-expanded"/></main-input-files-expanded>-->
            <file-groups-diffed-and-collated><xsl:copy-of select="$file-groups-diffed-and-collated"/></file-groups-diffed-and-collated>
            <file-groups-with-stats><xsl:copy-of select="$file-groups-with-stats"/></file-groups-with-stats>
            <output-containers-prepped><xsl:copy-of select="$output-containers-prepped"/></output-containers-prepped>
            <html-output><xsl:copy-of select="$output-as-html"/></html-output>
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:for-each select="$global-notices">
            <xsl:message select="'= = = = ' || name(.) || ' = = = ='"/>
            <xsl:for-each select="tan:message">
                <xsl:message select="string(.)"/>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select="$file-groups-with-stats, $output-as-html">
            <xsl:call-template name="save-file">
                <xsl:with-param name="document-to-save" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


</xsl:stylesheet>
