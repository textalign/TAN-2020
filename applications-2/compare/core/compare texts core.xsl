<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for comparing texts. -->
    
    <xsl:include href="../../../functions-2/TAN-function-library.xsl"/>
    
    <xsl:variable name="output-directory-uri-resolved" as="xs:anyURI"
        select="resolve-uri($output-directory-uri, $calling-stylesheet-uri)"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:compare-texts'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="stylesheet-name" select="'Application to compare class 1 files'"/>
    <xsl:param name="tan:change-message" select="'Compared class 1 files.'"/>
    <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-10-06">Revise process that reinfuses a class 1 file with a diff/collate into a standard extra TAN function.</comment>
        </to-do>
    </xsl:param>
    

    <!-- The application -->
    
    
    <!-- Adjusting input parameters -->

    <xsl:variable name="main-input-resolved-uri-directories" as="xs:string*" select="
            for $i in $tan:main-input-relative-uri-directories
            return
                string(resolve-uri($i, $calling-stylesheet-uri))"/>
    
    <xsl:variable name="main-input-resolved-uris" as="xs:string*">
        <xsl:for-each select="$main-input-resolved-uri-directories">
            <xsl:try select="uri-collection(.)">
                <xsl:catch>
                    <xsl:message select="'Unable to get a uri collection from ' || ."/>
                </xsl:catch>
            </xsl:try>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="mirus-chosen" as="xs:string*"
        select="$main-input-resolved-uris[tan:filename-satisfies-regexes(., $tan:input-filenames-must-match-regex, $tan:input-filenames-must-not-match-regex)]"
    />
    
    <xsl:variable name="check-top-level-div-ns" as="xs:boolean" select="string-length($exclude-top-level-divs-with-attr-n-matching-what) gt 0"/>
    
    
    
    
    <!-- This application has many different parameters, and a slight change in one can radically alter the kind of results achieved. It is difficult
        to keep track of them all, so the following global variable collects the key items and prepares them for messaging.-->
    
    <xsl:variable name="notices" as="element()">
        <notices>
            <input_selection>
                <message><xsl:value-of select="'Main input directory: ' || $main-input-resolved-uri-directories"/></message>
                <xsl:if test="string-length($tan:input-filenames-must-match-regex) gt 0">
                    <message><xsl:value-of select="'Restricted to files with filenames matching: ' || $tan:input-filenames-must-match-regex"/></message>
                </xsl:if>
                <xsl:if test="string-length($tan:input-filenames-must-not-match-regex) gt 0">
                    <message><xsl:value-of select="'Avoiding any files with filenames matching: ' || $tan:input-filenames-must-not-match-regex"/></message>
                </xsl:if>
                <message><xsl:value-of select="'Found ' || string(count($mirus-chosen)) || ' input files: ' || string-join($mirus-chosen, '; ')"/></message>
                <xsl:if test="$check-top-level-div-ns">
                    <message><xsl:value-of select="'Excluding top-level divs whose @n values match ' || $exclude-top-level-divs-with-attr-n-matching-what"/></message>
                </xsl:if>
                <message><xsl:value-of select="'Exclude orphaned top-level divs? ' || $restrict-to-matching-top-level-div-attr-ns"/></message>
            </input_selection>
            <input_alteration>
                <xsl:if test="count($tan:diff-and-collate-input-batch-replacements) gt 0">
                    <message><xsl:value-of select="string(count($tan:diff-and-collate-input-batch-replacements)) || ' batch replacements applied globally, in this order:'"/></message>
                    <xsl:for-each select="$tan:diff-and-collate-input-batch-replacements">
                        <message><xsl:value-of select="'Global replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                    </xsl:for-each>
                </xsl:if>
                <message><xsl:value-of select="'Ignore case differences: ' || string($tan:ignore-case-differences)"/></message>
                <message><xsl:value-of select="'Ignore combining marks: ' || string($tan:ignore-combining-marks)"/></message>
                <message><xsl:value-of select="'Ignore character component differences: ' || string($tan:ignore-character-component-differences)"/></message>
                <message><xsl:value-of select="'Ignore punctuation differences: ' || string($tan:ignore-punctuation-differences)"/></message>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'grc'">
                    <message><xsl:value-of select="'Ignore differences in Greek between grave and acute accents: ' || string($ignore-greek-grave-acute-distinction)"/></message>
                </xsl:if>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'lat'">
                    <xsl:if test="$apply-to-latin-batch-replacement-set-1">
                        <message><xsl:value-of select="'Applying the following batch replacements to all Latin text: '"/></message>
                        <xsl:for-each select="$tan:latin-batch-replacements-1">
                            <message><xsl:value-of select="'Latin replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'syr'">
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
                <message><xsl:value-of select="'Treat differences word-for-word (not character-for-character)? ' || string($tan:snap-to-word)"/></message>
            </collation_handling>
            <statistics>
                <xsl:if test="matches($tan:unimportant-change-regex, '\S')">
                    <message><xsl:value-of select="'Characters ignored in statistics (regular expression): ' || $tan:unimportant-change-regex"/></message>
                </xsl:if>
                <xsl:if test="count($tan:unimportant-change-character-aliases) gt 0">
                    <message><xsl:value-of select="string(count($tan:unimportant-change-character-aliases)) || ' groups of changes will be ignored for the sake of statistical analysis.'"/></message>
                    <xsl:for-each select="$tan:unimportant-change-character-aliases">
                        <message><xsl:value-of select="'Character alias ' || string(position()) || ': ' || string-join('[' || * || ']', ' ')"/></message>
                    </xsl:for-each>
                </xsl:if>
            </statistics>
            <output>
                <message><xsl:value-of select="'Collate/diff results in the HTML file are replaced with their original form (e.g., ignored punctuation is restored, capitalization is restored): ' || string($replace-diff-results-with-pre-alteration-forms)"/></message>
            </output>
        </notices>
    </xsl:variable>
    
    
    
    
    
    
    <!-- Beginning of main input -->
    
    <xsl:variable name="main-input-files" select="tan:open-file($mirus-chosen)" as="document-node()*"/>
    
    <xsl:variable name="main-input-files-filtered" as="document-node()*">
        <xsl:for-each select="$main-input-files">
            <xsl:choose>
                <xsl:when
                    test="$restrict-to-matching-top-level-div-attr-ns and not(exists(*/tan:head))"/>
                <xsl:when test="exists(*[@_archive-path][not(self::w:document)])"/>
                <xsl:otherwise>
                    <xsl:sequence select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="main-input-files-resolved" as="document-node()*" select="
            for $i in $main-input-files-filtered
            return
                if (exists($i/*/tan:head)) then
                    tan:resolve-doc($i, true(), ())
                else
                    $i"/>
    
    <!-- Get string value of other input text; no normalization occurs -->
    <xsl:variable name="main-input-files-prepped" as="document-node()*">
        <xsl:apply-templates select="$main-input-files-filtered" mode="prepare-input"/>
    </xsl:variable>
    
    
    <xsl:mode name="prepare-input" on-no-match="shallow-copy"/>
    
    <!-- Skip docx components that aren't documents -->
    <xsl:template match="document-node()[*/@_archive-path]" priority="-2" mode="prepare-input"/>
    <xsl:template match="document-node()[w:document]" mode="prepare-input">
        <xsl:document>
            <xsl:apply-templates mode="#current"/>
        </xsl:document>
    </xsl:template>
    
    <!-- Word documents get plain text only -->
    <xsl:template match="/w:document" priority="1" mode="prepare-input">
        <xsl:variable name="this-filename" as="xs:string" select="tan:cfn(@xml:base)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="xml:lang" select="$default-language"/>
            <xsl:attribute name="grouping-key" select="$default-language"/>
            <xsl:attribute name="sort-key" select="$this-filename"/>
            <xsl:attribute name="label" select="replace($this-filename, '(%20|\.)', '_')"/>
            <xsl:sequence select="tan:docx-to-text(.)"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- For unparsed text use default language; if XML look for the first @xml:lang -->
    <xsl:template match="/*" mode="prepare-input">
        <xsl:variable name="this-base-uri" as="xs:anyURI" select="tan:base-uri(.)"/>
        <xsl:variable name="this-filename" as="xs:string" select="tan:cfn($this-base-uri)"/>
        <xsl:variable name="first-language" select="(descendant-or-self::*[@xml:lang][1]/@xml:lang)[1]" as="xs:string?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="xml:base" select="$this-base-uri"/>
            <xsl:attribute name="xml:lang" select="($first-language, $default-language)[1]"/>
            <xsl:attribute name="grouping-key" select="($first-language, $default-language)[1]"/>
            <xsl:attribute name="sort-key" select="$this-filename"/>
            <xsl:attribute name="label" select="replace($this-filename, '(%20|\.)', '_')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Ignore the tei header and tan header -->
    <xsl:template match="tan:head | tei:teiHeader" priority="1" mode="prepare-input tan:normalize-tree-space"/>
    
    <xsl:template match="*:div[@n]" mode="prepare-input">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$inject-attr-n">
                <xsl:sequence select="@n || ' '"/>
            </xsl:if>
            <xsl:if test="not(exists(@q))">
                <xsl:attribute name="q" select="generate-id(.)"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[not(@q)]" priority="-1" mode="prepare-input">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="q" select="generate-id(.)"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Normalize string value of TAN files -->
    <xsl:variable name="main-input-files-space-normalized" as="document-node()*" select="
            for $i in $main-input-files-prepped
            return
                if (
                (not(exists($i/*/tan:head)) and not($space-normalize-non-tan-input))
                or exists($i/*/@_archive-path) (: don't space-normalize docx components :)
                ) then
                    $i
                else
                    tan:normalize-tree-space($i, true())"/>
    
    <xsl:variable name="main-input-files-non-mixed" as="document-node()*" select="
            for $i in $main-input-files-space-normalized
            return
                tan:make-non-mixed($i)"/>


    <!-- This builds a series of XML documents with the diffs and collations, plus simple metadata on each file -->
    <xsl:variable name="file-groups-diffed-and-collated" as="document-node()*">
        <xsl:for-each-group select="$main-input-files-non-mixed" group-by="*/@grouping-key">
            <xsl:variable name="this-group-pos" select="position()"/>
            <xsl:variable name="this-group-name" as="xs:string" select="current-grouping-key()"/>
            <xsl:variable name="this-base-filename" as="xs:string">
                <xsl:choose>
                    <xsl:when test="string-length($output-base-filename) gt 0 and position() eq 1">
                        <xsl:sequence select="$output-base-filename"/>
                    </xsl:when>
                    <xsl:when test="string-length($output-base-filename) gt 0">
                        <xsl:sequence select="$output-base-filename || '-' || string(position())"/>
                    </xsl:when>
                    <xsl:when test="exists(current-group()[1]/*/@xml:base)">
                        <xsl:sequence select="tan:cfn(current-group()[1]/*/@xml:base) || '-compared'"/>
                    </xsl:when>
                    <xsl:when test="position() eq 1">
                        <xsl:sequence select="$this-group-name || '-compared'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$this-group-name || '-' || string(position()) || '-compared'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="this-group-count" select="count(current-group())"/>
            <xsl:variable name="these-group-labels" select="current-group()/*/@label"/>
            <xsl:variable name="this-group" as="document-node()+">
                <xsl:for-each select="current-group()">
                    <xsl:sort select="*/@sort-key"/>
                    <xsl:sequence select="."/>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="duplicate-top-level-div-attr-ns" as="xs:string*">
                <xsl:if test="$restrict-to-matching-top-level-div-attr-ns">
                    <xsl:for-each-group select="$this-group//*:body/*:div/@n" group-by=".">
                        <xsl:if test="count(current-group()) ge $this-group-count">
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:if>
                    </xsl:for-each-group> 
                </xsl:if>
            </xsl:variable>
            
            <xsl:variable name="these-langs" as="xs:string*"
                select="distinct-values($this-group/*/@xml:lang)"/>
            <xsl:variable name="extra-batch-replacements" as="element()*">
                <xsl:if test="$these-langs = 'lat' and $apply-to-latin-batch-replacement-set-1">
                    <xsl:sequence select="$tan:latin-batch-replacements-1"/>
                </xsl:if>
                <xsl:if test="$these-langs = 'syr' and $apply-to-syriac-batch-replacement-set-1">
                    <xsl:sequence select="$syriac-batch-replacements-1"/>
                </xsl:if>
            </xsl:variable>   
            <xsl:variable name="all-batch-replacements" as="element()*"
                select="$tan:diff-and-collate-input-batch-replacements, $extra-batch-replacements, $additional-batch-replacements"
            />
            
            <xsl:variable name="these-raw-texts" as="xs:string*" select="
                    for $i in $this-group
                    return
                        if (exists($duplicate-top-level-div-attr-ns)) then
                            string-join($i//*:body/*:div[@n = $duplicate-top-level-div-attr-ns])
                        else
                            string($i)"/>
            <xsl:variable name="these-texts-normalized-1" as="xs:string*"
                select="
                    if (count($all-batch-replacements) gt 0) then
                        (for $i in $these-raw-texts
                        return
                            tan:batch-replace($i, $all-batch-replacements))
                    else
                        $these-raw-texts"
            />
            
            <xsl:variable name="these-texts-normalized-2" as="xs:string*"
                select="
                    if ($tan:ignore-character-component-differences) then
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
                        <xsl:sequence select="$these-texts-normalized-2"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            

            <xsl:variable name="finalized-texts-to-compare" as="xs:string*"
                select="
                    if ($tan:ignore-case-differences) then
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
                            <xsl:value-of select="string-join((., string($this-pos)), '_')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
            <xsl:if test="$diagnostics-on">
                <xsl:message select="'Diagnostics on, $file-groups-diffed-and-collated'"/>
                <xsl:message select="'Group pos, name, count:', $this-group-pos, $this-group-name, $this-group-count"
                />
                <xsl:message select="'Group labels: ' || string-join($these-group-labels, ', ')"/>
                <xsl:message select="'Duplicate top level ns: ' || string-join($duplicate-top-level-div-attr-ns, ', ')"/>
                <xsl:message select="'These langs: ' || string-join($these-langs, ', ')"/>
                <xsl:message select="'Extra batch replacements:', $extra-batch-replacements"/>
                <xsl:message select="'Raw texts: ' || string-join(tan:ellipses($these-raw-texts, 40), ' || ')"/>
                <xsl:message select="'Texts pass 1: ' || string-join(tan:ellipses($these-texts-normalized-1, 40), ' || ')"/>
                <xsl:message select="'Texts pass 2: ' || string-join(tan:ellipses($these-texts-normalized-2, 40), ' || ')"/>
                <xsl:message select="'Texts pass 3: ' || string-join(tan:ellipses($these-texts-normalized-3, 40), ' || ')"/>
                <xsl:message select="'Final texts: ' || string-join(tan:ellipses($finalized-texts-to-compare, 40), ' || ')"/>
                <xsl:message select="'Duplicate labels:', $these-duplicate-labels"/>
                <xsl:message select="'Labels (revised): ' || string-join($these-labels-revised, ', ')"/>
            </xsl:if>


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
                            _target-uri="{$output-directory-uri-resolved || $this-base-filename || '.xml'}">
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
                                    uri="{*/@xml:base}" ref="{$this-id-ref}"/>
                            </xsl:for-each>
                            

                            <xsl:choose>
                                
                                <xsl:when test="count($finalized-texts-to-compare) eq 2">
                                    <xsl:copy-of
                                        select="tan:adjust-diff(tan:diff($finalized-texts-to-compare[1], $finalized-texts-to-compare[2], $tan:snap-to-word))"
                                    />
                                </xsl:when>
                                
                                <xsl:otherwise>
                                    <xsl:copy-of
                                        select="tan:collate($finalized-texts-to-compare, $these-labels-revised, $preoptimize-string-order, true(), true(), $tan:snap-to-word)"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </group>
                    </xsl:document>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:variable>
    
    
    <!-- Next, build a statistical profile and weigh the results. -->
    
    <!-- This does the same as tan:infuse-diff-and-collate-stats() but retains
    the XML's document character -->
    <xsl:variable name="xml-output-pass-1" as="document-node()*">
        <xsl:apply-templates select="$file-groups-diffed-and-collated" mode="tan:infuse-diff-and-collate-stats">
            <xsl:with-param name="unimportant-change-character-aliases" as="element()*"
                select="$tan:unimportant-change-character-aliases" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    
    <!-- At this point, the master XML data should be finished. From this point forward we deal with 
    presenting that data legibly via HTML. -->
    
    
    <!-- PREPARATION FOR HTML -->
    
    <!-- In each diff/collate report, find the primary input file. Remove the diff / collation results. Apply templates
        to the primary file with the diff/collation results as a tunnel parameter, to be infused into the text nodes
        of the primary file. That allows us to begin a basic structure of presenting the diff/collation results in the
        form of the primary document, to improve legibility.
    -->
    <!-- Remove temporary attributes we're not interested in -->
    <!-- We also insert the global notices, and replace the diff or collation, if required. -->
    
    
    <xsl:variable name="xml-to-html-prep" as="document-node()*">
        <xsl:apply-templates select="$xml-output-pass-1" mode="prep-for-html"/>
    </xsl:variable>
    
    
    <xsl:mode name="prep-for-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:group" mode="prep-for-html">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            
            <xsl:copy-of select="$notices"/>
            
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="last-wit-ref" tunnel="yes" as="xs:string?"
                    select="tan:stats/tan:witness[last()]/@ref"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:stats" mode="prep-for-html">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:if test="$replace-diff-results-with-pre-alteration-forms">
                <div xmlns="http://www.w3.org/1999/xhtml" class="note warning">There may be
                    discrepancies between the statistics and the displayed text. The original texts
                    may have been altered before the text comparison and statistics were generated
                    (see any attached notices), but for legibility the results styled according to
                    the original text form. To see the difference that justifies the statistics, see
                    the original input or any supplementary output.</div>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:diff[tan:common or tan:a or tan:b]" mode="prep-for-html">
        <xsl:variable name="diff-a-file-base-uri" select="../tan:stats/tan:witness[1]/tan:uri" as="element()?"/>
        <xsl:variable name="diff-b-file-base-uri" select="../tan:stats/tan:witness[2]/tan:uri" as="element()?"/>
        
        <xsl:variable name="diff-a-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $diff-a-file-base-uri]"
        />
        <xsl:variable name="diff-b-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $diff-b-file-base-uri]"
        />
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on, template mode prep-for-html on tan:diff'"/>
            <xsl:message select="'a base uri: ' || $diff-a-file-base-uri"/>
            <xsl:message select="'b base uri: ' || $diff-b-file-base-uri"/>
            <xsl:message select="'a text: ' || string($diff-a-prepped-file)"/>
            <xsl:message select="'b text: ' || string($diff-b-prepped-file)"/>
            <xsl:message select="'This diff (orig): ', ."/>
            <xsl:message select="'This diff replaced with a and b: ', tan:replace-diff(
                string($diff-a-prepped-file),
                string($diff-b-prepped-file),
                ., false())"/>
        </xsl:if>
        
        
        <xsl:choose>
            <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                <xsl:copy-of select="
                        tan:replace-diff(
                        string($diff-a-prepped-file),
                        string($diff-b-prepped-file),
                        ., false())"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="tan:collation[tan:witness]" mode="prep-for-html">
        <xsl:param name="last-wit-ref" tunnel="yes" as="xs:string"/>
        <xsl:variable name="primary-file-base-uri"
            select="../tan:stats/tan:witness[@ref eq $last-wit-ref]/tan:uri" as="element()"/>
        <xsl:variable name="primary-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $primary-file-base-uri]"
        />
        
        <xsl:choose>
            <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                <xsl:sequence select="
                        tan:replace-collation(string($primary-prepped-file),
                        $last-wit-ref, .)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    
    
    
    <!--<xsl:variable name="html-output-pass-1" as="document-node()*">
        <xsl:apply-templates select="$xml-output-pass-1"
            mode="html-output-pass-1"/>
    </xsl:variable>-->
    
    <!--<!-\- Pass 1 goal: insert notices, set up stats as an html table, replace diff results with the 
        content of the primary file, do some preliminary filtering of the primary file. -\->
    <xsl:mode name="html-output-pass-1" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:group" mode="html-output-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>

            <xsl:copy-of select="$notices"/>

            <xsl:apply-templates mode="#current">
                <xsl:with-param name="last-wit-ref" tunnel="yes" as="xs:string?"
                    select="tan:stats/tan:witness[last()]/@ref"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:template match="tan:stats" mode="html-output-pass-1">
        <xsl:variable name="witness-ids" as="xs:string*" select="../tan:collation/tan:witness/@id"/>
        
        <table xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-stats'"/>
            <thead>
                <tr>
                    <th/>
                    <th/>
                    <th/>
                    <th colspan="3">Differences</th>
                </tr>
                <tr>
                    <th/>
                    <th>URI</th>
                    <th>Length</th>
                    <th>Number</th>
                    <th>Length</th>
                    <th>Portion</th>
                </tr>
            </thead>
            <tbody>
                <!-\- templates on venns/venn are applied after the table built by group/collation -\->
                <xsl:apply-templates select="* except (tan:venns | tan:note)" mode="#current"/>
            </tbody>
        </table>
        
        <xsl:if test="$replace-diff-results-with-pre-alteration-forms">
            <div class="note warning">There may be discrepancies between the statistics and the
                displayed text. The original texts may have been altered before the text comparison
                and statistics were generated (see any attached notices), but for legibility the
                results styled according to the original text form. To see the difference that
                justifies the statistics, see the original input or any supplementary output.</div>
        </xsl:if>
        
        <xsl:apply-templates select="tan:note" mode="#current"/>
        
        <xsl:if test="exists(../tan:collation/tan:witness/tan:commonality)">
            <div xmlns="http://www.w3.org/1999/xhtml">
                <div class="label">Pairwise Similarity</div>
                <div class="explanation">The table below shows the percentage of similarity of each
                    pair of versions, starting with the version that shows the least divergence from
                    the entire group and proceeding to versions that are most divergent. This table
                    is useful for identifying clusters and pairs of versions that are closest to
                    each other.</div>
                <table>
                    <xsl:attribute name="class" select="'e-' || name(.)"/>
                    <thead>
                        <tr>
                            <th/>
                            <xsl:for-each select="$witness-ids">
                                <th>
                                    <xsl:value-of select="."/>
                                </th>
                            </xsl:for-each>
                        </tr>
                    </thead>
                    <tbody>
                        <!-\- The following witnesses will normally be in order from most common to
                        the group to least common -\->
                        <xsl:apply-templates select="../tan:collation/tan:witness" mode="#current">
                            <xsl:with-param name="witness-ids" select="$witness-ids"/>
                        </xsl:apply-templates>
                    </tbody>
                </table>
            </div>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="tan:stats/*" mode="html-output-pass-1">
        <xsl:param name="last-wit-idref" tunnel="yes" as="xs:string?"/>
        <xsl:param name="diff-a-ref" tunnel="yes" as="xs:string?" select="@ref"/>
        <xsl:param name="diff-b-ref" tunnel="yes" as="xs:string?" select="@ref"/>
        
        <xsl:variable name="this-ref" as="xs:string">
            <xsl:choose>
                <xsl:when test="@id = 'a' and string-length($diff-a-ref) gt 0">
                    <xsl:sequence select="$diff-a-ref"/>
                </xsl:when>
                <xsl:when test="@id = 'b' and string-length($diff-b-ref) gt 0">
                    <xsl:sequence select="$diff-b-ref"/>
                </xsl:when>
                <xsl:when test="exists(@ref)">
                    <xsl:sequence select="@ref"></xsl:sequence>
                </xsl:when>
                <xsl:otherwise>aggregate</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="is-last-witness"
            select="
            if (string-length($last-wit-idref) gt 0) then
            ($this-ref = $last-wit-idref)
            else
            (following-sibling::*[1]/(self::tan:collation | self::tan:diff))"
        />
        <xsl:variable name="is-summary" select="self::tan:collation or self::tan:diff"/>
        <xsl:if test="$is-summary">
            <xsl:variable name="prec-wits" select="preceding-sibling::tan:witness"/>
            <tr class="averages" xmlns="http://www.w3.org/1999/xhtml">
                <td>
                    <div>averages</div>
                </td>
                <td/>
                <td class="e-length">
                    <xsl:value-of
                        select="
                        format-number(avg(for $i in $prec-wits/tan:length
                        return
                        number($i)), '0.0')"
                    />
                </td>
                <td class="e-diff-count">
                    <xsl:value-of
                        select="
                        format-number(avg(for $i in $prec-wits/tan:diff-count
                        return
                        number($i)), '0.0')"
                    />
                </td>
                <td class="e-diff-length">
                    <xsl:value-of
                        select="
                        format-number(avg(for $i in $prec-wits/tan:diff-length
                        return
                        number($i)), '0.0')"
                    />
                </td>
                <td class="e-diff-portion">
                    <xsl:value-of
                        select="
                        format-number(avg(for $i in $prec-wits/tan:diff-portion
                        return
                        number(replace($i, '%', '')) div 100), '0.0%')"
                    />
                </td>
            </tr>
        </xsl:if>
        <tr xmlns="http://www.w3.org/1999/xhtml">
            <xsl:copy-of select="@class"/>
            <!-\- The name of the witness, and the first column, for selection -\->
            <td>
                <div>
                    <xsl:value-of select="$this-ref"/>
                </div>
                <!-\- Do not perform the following if it is the last row of the table, a summary of
                the collation/diff. -\->
                <xsl:if test="not(self::tan:collation) and not(self::tan:diff)">
                    <div>
                        <xsl:attribute name="class"
                            select="
                            'last-picker' || (if ($is-last-witness) then
                            ' a-last'
                            else
                            ())"/>
                        <div>
                            <xsl:text>Tt</xsl:text>
                        </div>
                    </div>
                    <div>
                        <xsl:attribute name="class"
                            select="
                            'other-picker' || (if ($is-last-witness) then
                            ' a-other'
                            else
                            ())"/>
                        <div>
                            <xsl:text>Tt</xsl:text>
                        </div>
                    </div>
                    <div class="switch">
                        <div class="on">☑</div>
                        <div class="off" style="display:none">☐</div>
                    </div>
                </xsl:if>
            </td>
            <xsl:apply-templates mode="#current"/>
        </tr>
    </xsl:template>
    
    <xsl:template match="tan:stats/*/*" mode="html-output-pass-1">
        <td xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-' || name(.)"/>
            <xsl:apply-templates mode="#current"/>
        </td>
    </xsl:template>
    
    <xsl:template match="tan:note" mode="html-output-pass-1" priority="1">
        <div class="explanation" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:venns" priority="1" mode="html-output-pass-1">
        <div class="venns" xmlns="http://www.w3.org/1999/xhtml">
            <div class="label">Three-way Venns and Analysis</div>
            <div class="explanation">Versions are presented below in sets of three, with a Venn
                diagram for visualization. Numbers refer to the quantity of characters that diverge
                from common, shared text (that is, shared by all three, regardless of any other
                version).</div>
            <div class="explanation">The diagrams are useful for thinking about how a document was
                revised. The narrative presumes that versions A, B, and C represent consecutive
                editing stages in a document, and an interest in the position of B relative to the
                path from A to C. The diagrams also depict wasted work. Whatever is in B that is in
                neither A nor C represents text that B added that C deleted. Whatever is in A and C
                but not in B represent text deleted by B that was restored by C.</div>
            <div class="explanation">Although ideal for describing an editorial path where A, B, and
                C stand in direct relation to each other, the scenarios can be profitably used to
                study three versions whose relationship is unknown.</div>
            <div class="explanation">Note, some data combinations are impossible to draw accurately
                with a 3-circle Venn diagram (e.g., a 3-circle Venn diagram for items in the set
                {[a, z], [b, z], [c, z]} will always incorrectly show overlap for each pair of
                items).</div>
            <div class="explanation">The colors are fixed according to the A, B, and C components of
                the Venn diagram, not to the version labels, which change color from one Venn
                diagram to the next.</div>
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:venns/tan:venn" priority="1" mode="html-output-pass-1">
        <xsl:variable name="letter-sequence" select="('a', 'b', 'c')"/>
        <xsl:variable name="these-keys" select="tan:a | tan:b | tan:c"/>
        <xsl:variable name="this-id" select="'venn-' || string-join((tan:a, tan:b, tan:c), '-')"/>
        <xsl:variable name="common-part" select="tan:part[tan:a][tan:b][tan:c]"/>
        <xsl:variable name="other-parts" select="tan:part except $common-part"/>
        <xsl:variable name="single-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 1]"/>
        <xsl:variable name="double-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 2]"/>
        <xsl:variable name="common-length" select="number($common-part/tan:length)"/>
        <xsl:variable name="all-other-lengths" select="
                for $i in $other-parts/tan:length
                return
                    number($i)"/>
        <xsl:variable name="max-sliver-length" select="max($all-other-lengths)"/>
        <xsl:variable name="reduce-common-section-by" select="
                if ($common-length gt $max-sliver-length) then
                    ($common-length - $max-sliver-length)
                else
                    0"/>
        <xsl:variable name="these-labels" as="element()+">
            <div class="venn-a" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:value-of select="tan:a"/>
            </div>
            <div class="venn-b" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:value-of select="tan:b"/>
            </div>
            <div class="venn-c" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:value-of select="tan:c"/>
            </div>
        </xsl:variable>
        <div class="venn" xmlns="http://www.w3.org/1999/xhtml">
            <div class="label">
                <xsl:copy-of select="$these-labels"/>
            </div>
            <xsl:for-each select="'b'">
                <xsl:variable name="this-letter" select="."/>
                <xsl:variable name="other-letters" select="$letter-sequence[not(. = $this-letter)]"/>
                <xsl:variable name="start-letter" select="$other-letters[1]"/>
                <xsl:variable name="end-letter" select="$other-letters[2]"/>
                <xsl:variable name="this-letter-label" select="$these-keys[name(.) = $this-letter]"/>
                <xsl:variable name="start-letter-label"
                    select="$these-keys[name(.) = $start-letter]"/>
                <xsl:variable name="end-letter-label" select="$these-keys[name(.) = $end-letter]"/>
                <xsl:variable name="this-div-label" select="$these-labels[. = $this-letter-label]"/>
                <xsl:variable name="start-div-label" select="$these-labels[. = $start-letter-label]"/>
                <xsl:variable name="end-div-label" select="$these-labels[. = $end-letter-label]"/>

                <xsl:variable name="this-nixed-insertions"
                    select="$single-parts[*[name(.) = $this-letter]]"/>
                <xsl:variable name="this-nixed-deletions"
                    select="$double-parts[not(*[name(.) = $this-letter])]"/>
                <xsl:variable name="start-unique" select="$single-parts[*[name(.) = $start-letter]]"/>
                <xsl:variable name="not-in-end"
                    select="$double-parts[not(*[name(.) = $end-letter])]"/>
                <xsl:variable name="not-in-start"
                    select="$double-parts[not(*[name(.) = $start-letter])]"/>
                <xsl:variable name="end-unique" select="$single-parts[*[name(.) = $end-letter]]"/>

                <xsl:variable name="journey-deletions"
                    select="number($start-unique/tan:length) + number($not-in-end/tan:length)"/>
                <xsl:variable name="journey-insertions"
                    select="number($not-in-start/tan:length) + number($end-unique/tan:length)"/>
                <xsl:variable name="journey-distance"
                    select="$journey-deletions + $journey-insertions"/>
                <xsl:variable name="this-traversal"
                    select="number($start-unique/tan:length) + number($not-in-start/tan:length)"/>
                <xsl:variable name="these-mistakes"
                    select="number($this-nixed-insertions/tan:length) + number($this-nixed-deletions/tan:length)"/>
                <xsl:variable name="these-likely-false-mistakes" as="xs:string*">
                    <xsl:analyze-string
                        select="string-join(($this-nixed-insertions/tan:texts/*/tan:txt, $this-nixed-deletions/tan:texts/*/tan:txt))"
                        regex="{string-join(((for $i in $tan:unimportant-change-character-aliases/tan:c return tan:escape($i)), $tan:unimportant-change-regex), '|')}"
                        flags="s">
                        <xsl:matching-substring>
                            <xsl:value-of select="."/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:variable name="this-likely-false-mistake-count"
                    select="string-length(string-join($these-likely-false-mistakes))"/>

                <xsl:variable name="diagnostics-on" select="false()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message
                        select="'Diagnostics on, calculating relative distance of intermediate version between start and end.'"/>
                    <xsl:message select="'Start unique length ' || $start-unique/tan:length"/>
                    <xsl:message select="'Not in end length ' || $not-in-end/tan:length"/>
                    <xsl:message select="'Not in start length ' || $not-in-start/tan:length"/>
                    <xsl:message select="'End unique length ' || $end-unique/tan:length"/>
                    <xsl:message select="'End unique length ' || $end-unique/tan:length"/>
                </xsl:if>

                <div>
                    <xsl:text>The distance from </xsl:text>
                    <xsl:copy-of select="$start-div-label"/>
                    <xsl:text> to </xsl:text>
                    <xsl:copy-of select="$end-div-label"/>
                    <xsl:text> is </xsl:text>
                    <xsl:value-of
                        select="string($journey-distance) || ' (' || string($journey-deletions) || ' characters deleted and ' || string($journey-insertions) || ' inserted). Intermediate version '"/>
                    <xsl:copy-of select="$this-div-label"/>
                    <xsl:value-of
                        select="' contributed ' || string($this-traversal) || ' characters to the end result (' || format-number(($this-traversal div $journey-distance), '0.0%') || '). '"/>
                    <xsl:if test="$these-mistakes gt 0">
                        <xsl:value-of
                            select="'But it inserted ' || $this-nixed-insertions/tan:length || ' characters that were deleted by '"/>
                        <xsl:copy-of select="$end-div-label"/>
                        <xsl:value-of
                            select="', and deleted ' || $this-nixed-deletions/tan:length || ' characters that were restored by '"/>
                        <xsl:copy-of select="$end-div-label"/>
                        <xsl:text>. </xsl:text>
                        <xsl:if test="number($this-nixed-insertions/tan:length) gt 0">
                            <xsl:text>Nixed insertions: </xsl:text>
                            <xsl:for-each-group select="$this-nixed-insertions/tan:texts/*/tan:txt"
                                group-by=".">
                                <xsl:sort select="count(current-group())" order="descending"/>
                                <xsl:if test="position() gt 1">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                                <div class="fragment">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </div>
                                <xsl:value-of select="' (' || string(count(current-group())) || ')'"
                                />
                            </xsl:for-each-group>
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                        <xsl:if test="number($this-nixed-deletions/tan:length) gt 0">
                            <xsl:text>Nixed deletions: </xsl:text>
                            <xsl:for-each-group select="$this-nixed-deletions/tan:texts/*/tan:txt"
                                group-by=".">
                                <xsl:sort select="count(current-group())" order="descending"/>
                                <xsl:if test="position() gt 1">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                                <div class="fragment">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </div>
                                <xsl:value-of select="' (' || string(count(current-group())) || ')'"
                                />
                            </xsl:for-each-group>
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                    </xsl:if>
                    <div class="bottomline">
                        <xsl:value-of select="
                                'Aggregate progress was ' || string($this-traversal - $these-mistakes + $this-likely-false-mistake-count) ||
                                ' (' || format-number((($this-traversal - $these-mistakes + $this-likely-false-mistake-count) div $journey-distance), '0.0%')"/>
                        <xsl:if test="$this-likely-false-mistake-count gt 0">
                            <xsl:text>, after adjusting for </xsl:text>
                            <xsl:value-of select="$this-likely-false-mistake-count"/>
                            <xsl:text> nixed deletions and insertions that seem negligible</xsl:text>
                        </xsl:if>
                        <xsl:text>). </xsl:text>
                    </div>
                </div>
            </xsl:for-each>
            <div id="{$this-id}" class="diagram"><!-\-  -\-></div>
            <xsl:if test="$common-length gt $max-sliver-length">
                <div class="explanation">
                    <xsl:text>*To show more accurately the differences between the three versions, the proportionate size of the central common section has been reduced by </xsl:text>
                    <xsl:value-of select="string($reduce-common-section-by)"/>
                    <xsl:text>, to match the size of the largest sliver. All other non-common slivers are rendered proportionate to one another.</xsl:text>
                </div>
            </xsl:if>
            <xsl:apply-templates select="tan:note" mode="#current"/>
        </div>
        <script xmlns="http://www.w3.org/1999/xhtml">
            <xsl:text>
var sets = [</xsl:text>
            <xsl:apply-templates select="tan:part" mode="#current">
                <xsl:with-param name="reduce-results-by" select="$reduce-common-section-by"/>
            </xsl:apply-templates>
            <xsl:text>
    ];

var chart = venn.VennDiagram()
    chart.wrap(false) 
    .width(320)
    .height(320);

var div = d3.select("#</xsl:text>
            <xsl:value-of select="$this-id"/>
            <xsl:text>").datum(sets).call(chart);
div.selectAll("text").style("fill", "white");
div.selectAll(".venn-circle path").style("fill-opacity", .6);

</xsl:text>
        </script>
    </xsl:template>
    
    <xsl:template match="tan:venn/tan:part" mode="html-output-pass-1">
        <xsl:param name="reduce-results-by" as="xs:numeric?"/>
        <xsl:variable name="this-parent" select=".."/>
        <xsl:variable name="these-letters" select="
                for $i in (tan:a, tan:b, tan:c)
                return
                    name($i)"/>
        <xsl:variable name="these-labels" select="../*[name(.) = $these-letters]"/>
        <!-\- unfortunately, the javascript library we use doesn't look at intersections but unions,
        so lengths need to be recalculated -\->
        <xsl:variable name="these-relevant-parts" select="
                ../tan:part[every $i in $these-letters
                    satisfies *[name(.) = $i]]"/>
        <xsl:variable name="these-relevant-lengths" select="$these-relevant-parts/tan:length"/>

        <xsl:variable name="total-length" select="
                sum(for $i in ($these-relevant-lengths)
                return
                    number($i)) - $reduce-results-by"/>
        <xsl:variable name="this-part-length" select="tan:length"/>

        <xsl:text>{sets:[</xsl:text>
        <xsl:value-of select="
                string-join((for $i in $these-labels
                return
                    ('&quot;' || $i || '&quot;')), ', ')"/>
        <xsl:text>], size: </xsl:text>
        <xsl:value-of select="$total-length"/>

        <xsl:value-of select="
                ', label: &quot;' || (if (count($these-letters) eq 3) then
                    '*'
                else
                    ()) || string($this-part-length) || '&quot;'"/>

        <xsl:text>}</xsl:text>
        <xsl:if test="exists(following-sibling::tan:part)">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;            </xsl:text>
    </xsl:template>
    
    
    
    
    <xsl:template match="tan:group/tan:diff | tan:group/tan:collation" mode="html-output-pass-1">
        <!-\- group/stats/witness sorts them according to label order whereas group/collation/witness (if a collation) 
            puts the least divergent witness at the top. We presume the former is the one of interest, and that 
            because many labels include numbers that allow them to be sorted in chronological order, the last is 
            the most interesting. -\->
        <xsl:variable name="primary-witness" as="element()"
            select="
                if (self::tan:diff) then
                    ../tan:stats/tan:witness[1]
                else
                    ../tan:stats/tan:witness[last()]"
        />
        <xsl:variable name="diff-b-file-base-uri" select="../tan:stats/tan:witness[2]/tan:uri" as="element()?"/>
        <xsl:variable name="primary-file-base-uri" select="$primary-witness/tan:uri" as="element()?"/>
        
        <xsl:variable name="primary-file-idref" select="$primary-witness/@ref" as="xs:string"/>
        <xsl:variable name="primary-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $primary-file-base-uri]"
        />
        <xsl:variable name="diff-b-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $diff-b-file-base-uri]"
        />
        
        <!-\-<xsl:variable name="first-class-1-doc-analyzed" select="tan:stamp-class-1-tree-with-text-data($first-class-1-doc)"/>-\->
        <xsl:variable name="primary-prepped-file-analyzed" as="document-node()?"
            select="tan:stamp-tree-with-text-data($primary-prepped-file, true())"/>
        
        <xsl:variable name="split-collation-where" select="$primary-prepped-file-analyzed//*[text()]" as="element()*"/>
        <xsl:variable name="split-count" select="count($split-collation-where)" as="xs:integer"/>

        <!-\- The strings may have been normalized before being processed in the diff/collate function.
            This next variable allows us to inject the results of the tan/diff with the pre-altered
            form of the primary string. If it's a diff we can do the same with the parts that are
            exclusively <b>. -\->
        <xsl:variable name="this-diff-or-collation-revised" as="element()">
            <xsl:choose>
                <xsl:when test="$replace-diff-results-with-pre-alteration-forms and self::tan:diff">
                    <xsl:copy-of select="
                            tan:stamp-diff-with-text-data(tan:replace-diff(
                            string($primary-prepped-file),
                            string($diff-b-prepped-file),
                            .))"/>
                </xsl:when>
                
                <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                    <xsl:sequence select="
                            tan:replace-collation(string($primary-prepped-file),
                            $primary-file-idref, .)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="leaf-elements-infused" as="element()*">
            <xsl:choose>
                <xsl:when test="self::tan:diff">
                    <xsl:iterate select="$split-collation-where">
                        <xsl:param name="diff-so-far" as="element()" select="$this-diff-or-collation-revised"/>
                        <xsl:variable name="this-string-last-pos"
                            select="xs:integer(@_pos) + xs:integer(@_len) - 1"/>
                        <xsl:variable name="first-diff-element-not-of-interest"
                            select="$diff-so-far/(tan:a | tan:common)[xs:integer(@_pos-a) gt $this-string-last-pos][1]"/>
                        <xsl:variable name="diff-elements-not-of-interest"
                            select="$first-diff-element-not-of-interest | $first-diff-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="diff-elements-of-interest"
                            select="$diff-so-far/(* except $diff-elements-not-of-interest)"/>
                        <xsl:variable name="last-diff-element-of-interest-with-this-witness"
                            select="$diff-elements-of-interest[self::tan:a or self::tan:common][last()]"/>
                        <xsl:variable name="last-deoiwtw-pos"
                            select="xs:integer($last-diff-element-of-interest-with-this-witness/@_pos-a)"/>
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
                                <!-\- If what follows is simply a <b> and the whole of the last diff element is desired, then that
                                <b> should be kept as well. We don't worry about cases where the next sibling is an <a> or <common>
                                because that is already accounted for by $first-diff-element-not-of-interest. -\->
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
                                    <xsl:attribute name="_pos-a" select="$last-deoiwtw-pos + $amount-needed"/>
                                    
                                    <xsl:value-of
                                        select="substring($last-diff-element-of-interest-with-this-witness, ($amount-needed, 0)[1] + 1)"
                                    />
                                </xsl:element>
                                <!-\- If only part of the last element of interest is kept, then if the next item is a <b>, it
                                should be pushed to the next iteration. -\->
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
                            <!-\- $last-diff-element-of-interest-with-this-witness/preceding-sibling::*, $fragment-to-keep,
                                $last-diff-element-of-interest-with-this-witness/(following-sibling::* except $diff-elements-not-of-interest) -\->
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
                        <!-\- In collation output it is @pos not @_pos -\->
                        <xsl:variable name="first-collation-element-not-of-interest" select="$collation-so-far/*[tan:wit[@ref = $primary-file-idref][xs:integer(@pos) gt $this-string-last-pos]][1]"/>
                        <xsl:variable name="collation-elements-not-of-interest" select="$first-collation-element-not-of-interest | $first-collation-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="collation-elements-of-interest" select="$collation-so-far/(* except $collation-elements-not-of-interest)"/>
                        <xsl:variable name="last-collation-element-of-interest-with-this-witness" select="$collation-elements-of-interest[tan:wit[@ref = $primary-file-idref]][last()]"/>
                        <xsl:variable name="last-ceoiwtw-pos" select="xs:integer($last-collation-element-of-interest-with-this-witness/tan:wit[@ref = $primary-file-idref]/@pos)"/>
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
                            <!-\-<xsl:copy-of select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"/>-\->
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
        
        <xsl:variable name="primary-file-adjusted" select="tan:prepare-to-convert-to-html($primary-prepped-file)" as="document-node()"/>
        
        <xsl:variable name="witness-ids" as="xs:string*" select="tan:witness/@id"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode infuse-class-1-with-diff-or-collation'"/>
            <xsl:message select="'First class 1 base uri: ' || $primary-file-base-uri"/>
            <xsl:message select="'Split diff or collation where? ' || string-join($split-collation-where/@_pos, ', ')"/>
            <!-\-<xsl:message select="'First infused leaf element: ', $leaf-elements-infused[1]"/>-\->
        </xsl:if>
        
        <!-\-<test03>
            <ppf><xsl:copy-of select="$primary-prepped-file"/></ppf>
            <ppfa><xsl:copy-of select="$primary-prepped-file-analyzed"/></ppfa>
            <split-collation-where><xsl:copy-of select="$split-collation-where"/></split-collation-where>
            <diff-or-collation-revised><xsl:copy-of select="$this-diff-or-collation-revised"/></diff-or-collation-revised>
            <!-\\-<lei><xsl:copy-of select="$leaf-elements-infused"/></lei>-\\->
            <!-\\-<pfa><xsl:copy-of select="$primary-file-adjusted"/></pfa>-\\->
        </test03>-\->
        
        <h2 xmlns="http://www.w3.org/1999/xhtml">Comparison</h2>
        <xsl:copy>
            <!-\-<xsl:copy-of select="tan:witness"/>-\->
            <xsl:apply-templates select="$primary-file-adjusted"
                mode="infuse-primary-file-with-diff-results">
                <xsl:with-param name="element-replacements" tunnel="yes"
                    select="$leaf-elements-infused"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="tan:witness" mode="html-output-pass-1">
        <!-\- This template completes the <table> designed to show pairwise similarity, currently
        placed just after <stats> -\->
        <xsl:param name="witness-ids"/>
        <xsl:variable name="commonality-children" select="tan:commonality"/>
        <tr xmlns="http://www.w3.org/1999/xhtml">
            <td>
                <xsl:value-of select="@id"/>
            </td>
            <xsl:for-each select="$witness-ids">
                <xsl:variable name="this-id" select="."/>
                <xsl:variable name="this-commonality"
                    select="$commonality-children[@with = $this-id]"/>
                <td>
                    <xsl:if test="exists($this-commonality)">
                        <xsl:variable name="this-commonality-number"
                            select="number($this-commonality)"/>
                        <xsl:attribute name="style"
                            select="'background-color: rgba(0, 128, 0, ' || string($this-commonality-number * $this-commonality-number * 0.6) || ')'"/>
                        <xsl:value-of select="format-number($this-commonality-number * 100, '0.0')"
                        />
                    </xsl:if>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>
    
    
    
    <xsl:mode name="infuse-primary-file-with-diff-results" on-no-match="shallow-copy"/>
    
    <xsl:template match="comment() | processing-instruction()"
        mode="infuse-primary-file-with-diff-results"/>
    
    <xsl:template match="*[@q]" mode="infuse-primary-file-with-diff-results">
        <xsl:param name="element-replacements" tunnel="yes" as="element()*"/>
        <xsl:variable name="context-q" select="@q"/>
        <xsl:variable name="this-substitute" select="$element-replacements[@q eq $context-q]"/>
        <xsl:choose>
            <xsl:when test="exists($this-substitute)">
                <xsl:apply-templates select="$this-substitute" mode="adjust-diff-infusion"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-\- get rid of attributes we will not use for the rest of the process, and do not want
    displayed in the HTML -\->
    <xsl:template match="@q | tei:*/@part | tei:*/@org | tei:*/@sample |
        /tei:TEI/@* | tan:TAN-T/@*"
        mode="infuse-primary-file-with-diff-results"/>
    
    
    <xsl:mode name="adjust-diff-infusion" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:_text" mode="adjust-diff-infusion">
        <!-\- drop the elements temporarily wrapping text -\->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:c | tan:u" mode="adjust-diff-infusion">
        <xsl:param name="last-wit-ref" as="xs:string?" tunnel="yes"/>
        <xsl:variable name="wit-refs" as="xs:string*" select="tan:wit/@ref"/>
        <xsl:variable name="class-values" as="xs:string*" select="
                (for $i in $wit-refs
                return
                    'a-w-' || $i),
                (if ($last-wit-ref = $wit-refs) then
                    ('a-last', 'a-other')
                else
                    ())"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="string-join($class-values, ' ')"/>
            <!-\- This is to populate a tooltip hover device to show which versions attest to the reading -\->
            <div class="wits" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:sequence select="string-join($wit-refs, ' ')"/>
            </div>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:b" mode="adjust-diff-infusion">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="'a-last a-other'"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-\- We don't need the witnesses in the HTML file because a tooltip lets the reader know which 
    witnesses attest to a given reading. But this could be adapted in the future, esp. to make use of
    @pos -\->
    <xsl:template match="tan:wit" mode="adjust-diff-infusion"/>-->
    
    
    
    <!--<xsl:variable name="html-output-pass-2" as="document-node()*" select="tan:prepare-to-convert-to-html($html-output-pass-1)"/>-->
    
    
    
    <!--<xsl:variable name="html-output-pass-3" as="document-node()*" select="tan:convert-to-html($html-output-pass-2, true())"/>-->
    
    
    <xsl:variable name="html-output-pass-3" as="document-node()*">
        <xsl:for-each select="$xml-to-html-prep/*">
            <xsl:variable name="primary-witness" as="element()"
                select="tan:stats/tan:witness[last()]"/>
            <xsl:variable name="primary-file-base-uri" select="$primary-witness/tan:uri" as="element()?"/>
            
            <xsl:variable name="primary-file-idref" select="$primary-witness/@ref" as="xs:string"/>
            <xsl:variable name="primary-prepped-file" as="document-node()"
                select="($main-input-files-non-mixed)[*/@xml:base eq $primary-file-base-uri]"
            />
            <xsl:variable name="primary-prepped-file-adjusted" as="document-node()">
                <xsl:apply-templates select="$primary-prepped-file" mode="adjust-primary-tree-for-html"></xsl:apply-templates>
            </xsl:variable>
            
            <xsl:document>
                <xsl:sequence
                    select="tan:diff-or-collate-to-html(., $primary-file-idref, $primary-prepped-file-adjusted/*)"
                />
            </xsl:document>
        </xsl:for-each>
    </xsl:variable>
    
    
    <xsl:mode name="adjust-primary-tree-for-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*/@*" mode="adjust-primary-tree-for-html"/>
    
    
    <xsl:variable name="html-output-pass-4" as="document-node()*">
        <xsl:apply-templates select="$html-output-pass-3" mode="html-output-pass-4"/>
        
    </xsl:variable>
    
    
    <xsl:mode name="html-output-pass-4" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*" mode="html-output-pass-4">
        <xsl:variable name="this-title" as="xs:string?">
            <xsl:sequence
                select="'Comparison of ' || tan:cardinal(xs:integer(tan:find-class(., 'a-count')))
                || ' files'"
            />
        </xsl:variable>
        <xsl:variable name="this-subtitle" as="xs:string?"
            select="'String differences and analyses across ' || replace(string-join(tan:cfne(tan:find-class(., 'e-file')/*[tan:has-class(., 'a-uri')]), ', '), '%20', ' ')"
        />
        <xsl:variable name="this-target-uri" select="replace(@_target-uri, '\w+$', 'html')"/>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="_target-format">xhtml-noindent</xsl:attribute>
            <xsl:attribute name="_target-uri" select="$this-target-uri"/>
            <head>
                <title>
                    <xsl:value-of select="string-join(($this-title, $this-subtitle), ': ')"/>
                </title>
                <!-- TAN css attend to some basic style issues common to TAN converted to HTML. -->
                <link rel="stylesheet"
                    href="{tan:uri-relative-to($resolved-uri-to-diff-css, $this-target-uri)}"
                    type="text/css">
                    <!-- Inserted comments ensure that the elements do not close and make them unreadable to the browser -->
                    <xsl:comment/>
                </link>
                <!-- The TAN JavaScript code uses jQuery. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-jquery, $this-target-uri)}">
                    <xsl:comment/>
                </script>
                <!-- The d3js library is required for use of the Venn JavaScript library -->
                <script src="https://d3js.org/d3.v5.min.js">
                    <xsl:comment/>
                </script>
                <!-- The Venn JavaScript library: https://github.com/benfred/venn.js/ -->
                <script src="{tan:uri-relative-to($resolved-uri-to-venn-js, $this-target-uri)}">
                    <xsl:comment/>
                </script>
            </head>
            <body>
                <h1>
                    <xsl:value-of select="$this-title"/>
                </h1>
                <div class="subtitle">
                    <xsl:value-of select="$this-subtitle"/>
                </div>
                <div class="timedate">
                    <xsl:value-of
                        select="'Comparison generated ' || format-dateTime(current-dateTime(), '[MNn] [D], [Y], [h]:[m01] [PN]')"
                    />
                </div>
                <xsl:apply-templates mode="#current"/>
                
                <!-- TAN JavaScript comes at the end, to ensure the DOM is loaded. The file supports manipulation of the sources and their appearance. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-diff-js, $this-target-uri)}"><!--  --></script>
                <!-- The TAN JavaScript library provides some generic functionality across all TAN HTML output -->
                <script src="{tan:uri-relative-to($resolved-uri-to-TAN-js, $this-target-uri)}"><!--  --></script>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="html:div[tan:has-class(., ('e-txt', 'e-a', 'e-b', 'e-common'))]/text()" mode="html-output-pass-4">
        <xsl:analyze-string select="." regex="\r?\n">
            <xsl:matching-substring>
                <xsl:text>¶</xsl:text>
                <xsl:element name="br" namespace="http://www.w3.org/1999/xhtml"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="tan:parse-a-hrefs(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template
        match="html:div[tan:has-class(., ('a-cgk', 'a-count', 'e-group-name', 'e-group-label', 'e-file', 'a-part', 'a-org',
        'a-sample'))]"
        mode="html-output-pass-4"/>
    
    
    
    <xsl:variable name="resolved-uri-to-diff-css" as="xs:string"
        select="($output-directory-uri-resolved || 'css/diff.css')"/>
    <xsl:variable name="resolved-uri-to-TAN-js" as="xs:string"
        select="($output-directory-uri-resolved || 'js/tan2020.js')"/>
    <xsl:variable name="resolved-uri-to-diff-js" as="xs:string"
        select="($output-directory-uri-resolved || 'js/diff.js')"/>
    <xsl:variable name="resolved-uri-to-jquery" as="xs:string"
        select="($output-directory-uri-resolved || 'js/jquery.js')"/>
    <xsl:variable name="resolved-uri-to-venn-js" as="xs:string"
        select="($output-directory-uri-resolved || 'js/venn.js/venn.js')"/>
    

    
    
    <xsl:mode name="return-final-messages" on-no-match="shallow-skip"/>
    
    <xsl:template match="html:script/@src | @href" mode="return-final-messages">
        <xsl:variable name="target-uri" select="root(.)/*/@_target-uri" as="xs:string"/>
        <xsl:variable name="this-link-resolved" select="resolve-uri(., $target-uri)" as="xs:anyURI"/>
        <xsl:if test="not(unparsed-text-available($this-link-resolved))">
            <xsl:message select="'Unparsed text not available at ' || . || ' relative to ' || $target-uri || '. See ' || path(.)"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:global-notices/*" mode="return-final-messages">
        <xsl:message select="'= = = = ' || name(.) || ' = = = ='"/>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:message" mode="return-final-messages">
        <xsl:message select="string(.)"/>
    </xsl:template>
    
    
    

    <!-- Main output -->
    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="false()"/>
    <xsl:output indent="yes" use-character-maps="tan:see-special-chars"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Output diagnostics on for ' || static-base-uri()"/>
        <xsl:apply-templates select="$notices" mode="return-final-messages"/>
        <diagnostics>
            <input-directories count="{count($main-input-resolved-uri-directories)}"><xsl:sequence select="$main-input-resolved-uri-directories"/></input-directories>
            <main-input-resolved-uris count="{count($main-input-resolved-uris)}"><xsl:sequence select="$main-input-resolved-uris"/></main-input-resolved-uris>
            <MIRUs-chosen count="{count($mirus-chosen)}"><xsl:sequence select="$mirus-chosen"/></MIRUs-chosen>
            <main-input-files count="{count($main-input-files)}"><xsl:copy-of select="tan:shallow-copy($main-input-files/*)"/></main-input-files>
            <main-input-files-filtered count="{count($main-input-files-filtered)}"><xsl:copy-of select="tan:shallow-copy($main-input-files-filtered/*)"/></main-input-files-filtered>
            <main-input-files-prepped count="{count($main-input-files-prepped)}"><xsl:sequence select="$main-input-files-prepped"/></main-input-files-prepped>
            <main-input-files-space-norm count="{count($main-input-files-space-normalized)}"><xsl:sequence select="$main-input-files-space-normalized"/></main-input-files-space-norm>
            <main-input-files-non-mixed count="{count($main-input-files-non-mixed)}"><xsl:sequence select="$main-input-files-non-mixed"/></main-input-files-non-mixed>
            <output-dir><xsl:value-of select="$output-directory-uri-resolved"/></output-dir>
            <file-groups-diffed-and-collated><xsl:copy-of select="$file-groups-diffed-and-collated"/></file-groups-diffed-and-collated>
            <xml-output-pass-1><xsl:copy-of select="$xml-output-pass-1"/></xml-output-pass-1>
            <xml-to-html-prep><xsl:copy-of select="$xml-to-html-prep"/></xml-to-html-prep>
            <!--<html-output-pass-1><xsl:copy-of select="$html-output-pass-1"/></html-output-pass-1>-->
            <!--<html-output-pass-2><xsl:copy-of select="$html-output-pass-2"/></html-output-pass-2>-->
            <html-output-pass-3><xsl:copy-of select="$html-output-pass-3"/></html-output-pass-3>
            <html-output-pass-4><xsl:copy-of select="$html-output-pass-4"/></html-output-pass-4>
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <!-- The main output template returns only secondary output, one HTML page per
            group of compared texts, plus messages. -->
        <xsl:apply-templates select="$notices, $xml-output-pass-1, $html-output-pass-4"
            mode="return-final-messages"/>
        <!--<xsl:for-each select="$global-notices">
            <xsl:message select="'= = = = ' || name(.) || ' = = = ='"/>
            <xsl:for-each select="tan:message">
                <xsl:message select="string(.)"/>
            </xsl:for-each>
        </xsl:for-each>-->
        <xsl:for-each select="$xml-output-pass-1, $html-output-pass-4">
            <xsl:call-template name="tan:save-file">
                <xsl:with-param name="document-to-save" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    
</xsl:stylesheet>
