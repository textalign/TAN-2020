<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    <!-- Shared templates for turning the output of tan:diff() and tan:collate(), perhaps
    after being passed through tan:infuse-diff-and-collate-stats(), into HTML. Once statted,
    you should have something like (basic outlines): -->
    <!--
        group(
            stats,
            file(@length, @uri, @ref)*,
            (collation(
                witness(
                    commonality(@with, text)*
                )+,
                (
                    u(
                        txt(text),
                        wit(@ref)+
                    )* &
                    c(
                        txt(text),
                        wit(@ref, @pos)+
                    )*
                )
            )) |
            (diff(
                a((@_pos, @_len)?, text)* &
                b((@_pos, @_len)?, text)* &
                common((@_pos, @_len)?, text)*
            ))
        )
    -->
    
    <!-- Result adjustments -->
    
    <!-- In the HTML output, should an attempt be made to convert resultant diffs back to their pre-adjustment forms (true()) or not? -->
    <xsl:param name="replace-diff-results-with-pre-alteration-forms" as="xs:boolean" select="true()"/>
    
    <!-- What text differences should be ignored when compiling difference statistics? Example, [\r\n] ignores any deleted or inserted line endings. Such differences will still be visible, but they will be ignored for the purposes of statistics. -->
    <xsl:variable name="unimportant-change-regex" as="xs:string" select="'[\r\n]'"/>
    
    

    <!-- HTML TABLE: for basic stats about each version, and selection -->
    <xsl:template match="tan:stats" mode="diff-and-collate-to-html">
        <xsl:param name="raw-texts" tunnel="yes" as="xs:string*"/>
        <xsl:param name="last-wit-idref" tunnel="yes" as="xs:string?"/>
        <xsl:param name="include-text-change-warning" tunnel="yes" as="xs:boolean" select="false()"/>
        <xsl:variable name="first-text" select="$raw-texts[1]"/>
        <xsl:variable name="corresponding-text" select="../tan:diff/(tan:a | tan:common), 
            ../tan:collation/*[tan:wit/@ref = $last-wit-idref]/tan:txt"/>
        <xsl:variable name="first-text-differs" select="not($first-text eq string-join($corresponding-text))"/>
        <table xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-' || name(.)"/>
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
                <!-- templates on venns/venn are applied after the table built by group/collation -->
                <xsl:apply-templates select="* except (tan:venns, tan:note)" mode="#current"/>
            </tbody>
        </table>
        <xsl:if test="$include-text-change-warning or ($replace-diff-results-with-pre-alteration-forms and $first-text-differs)">
            <div class="note warning">There may be discrepancies between the statistics and the
                displayed text. The original texts may have been altered before the text comparison
                and statistics were generated (see any attached notices), but for legibility the
                results styled according to the original text form. To see the difference that
                justifies the statistics, see the original input or any supplementary output.</div>
        </xsl:if>
        <xsl:apply-templates select="tan:note" mode="#current"/>
    </xsl:template>

    <!-- one row per witness -->
    <xsl:template match="tan:stats/*" mode="diff-and-collate-to-html">
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
            <!-- The name of the witness, and the first column, for selection -->
            <td>
                <div>
                    <xsl:value-of select="$this-ref"/>
                </div>
                <!-- Do not perform the following if it is the last row of the table, a summary of
                the collation/diff. -->
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

    <xsl:template match="tan:stats/*/*" mode="diff-and-collate-to-html">
        <td xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-' || name(.)"/>
            <xsl:apply-templates mode="#current"/>
        </td>
    </xsl:template>

    <xsl:template match="tan:note" mode="diff-and-collate-to-html" priority="1">
        <div class="explanation" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:venns" priority="1" mode="diff-and-collate-to-html">
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

    <xsl:template match="tan:venns/tan:venn" priority="1" mode="diff-and-collate-to-html">
        <xsl:variable name="letter-sequence" select="('a', 'b', 'c')"/>
        <xsl:variable name="these-keys" select="tan:a | tan:b | tan:c"/>
        <xsl:variable name="this-id" select="'venn-' || string-join((tan:a, tan:b, tan:c), '-')"/>
        <xsl:variable name="common-part" select="tan:part[tan:a][tan:b][tan:c]"/>
        <xsl:variable name="other-parts" select="tan:part except $common-part"/>
        <xsl:variable name="single-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 1]"/>
        <xsl:variable name="double-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 2]"/>
        <xsl:variable name="common-length" select="number($common-part/tan:length)"/>
        <xsl:variable name="all-other-lengths"
            select="
                for $i in $other-parts/tan:length
                return
                    number($i)"/>
        <xsl:variable name="max-sliver-length" select="max($all-other-lengths)"/>
        <xsl:variable name="reduce-common-section-by"
            select="
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
                        regex="{string-join(((for $i in $unimportant-change-character-aliases/tan:c return tan:escape($i)), $unimportant-change-regex), '|')}"
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
                        <xsl:value-of
                            select="
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
            <div id="{$this-id}" class="diagram"><!--  --></div>
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

    <xsl:template match="tan:venn/tan:part" mode="diff-and-collate-to-html">
        <xsl:param name="reduce-results-by" as="xs:numeric?"/>
        <xsl:variable name="this-parent" select=".."/>
        <xsl:variable name="these-letters"
            select="
                for $i in (tan:a, tan:b, tan:c)
                return
                    name($i)"/>
        <xsl:variable name="these-labels" select="../*[name(.) = $these-letters]"/>
        <!-- unfortunately, the javascript library we use doesn't look at intersections but unions,
        so lengths need to be recalculated -->
        <xsl:variable name="these-relevant-parts"
            select="
                ../tan:part[every $i in $these-letters
                    satisfies *[name(.) = $i]]"/>
        <xsl:variable name="these-relevant-lengths" select="$these-relevant-parts/tan:length"/>

        <xsl:variable name="total-length"
            select="
                sum(for $i in ($these-relevant-lengths)
                return
                    number($i)) - $reduce-results-by"/>
        <xsl:variable name="this-part-length" select="tan:length"/>

        <xsl:text>{sets:[</xsl:text>
        <xsl:value-of
            select="
                string-join((for $i in $these-labels
                return
                    ('&quot;' || $i || '&quot;')), ', ')"/>
        <xsl:text>], size: </xsl:text>
        <xsl:value-of select="$total-length"/>

        <xsl:value-of
            select="
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
    
    
    <!-- MIDDLE SECTION, PERHAPS FILE -->
    
    <!-- File info has been integrated into the table of sources -->
    <xsl:template match="tan:group/tan:file" mode="diff-and-collate-to-html"/>


    <!-- MAIN SECTION, DIFF OR COLLATION -->
    
    <xsl:template match="tan:group/tan:diff" mode="diff-and-collate-to-html">
        <!-- If $raw-texts is populated, it is a tacit request to replace the diff with the original, raw text -->
        <xsl:param name="raw-texts" tunnel="yes" as="xs:string*"/>
        
        <xsl:variable name="diff-replaced" as="element()">
            <xsl:choose>
                <xsl:when
                    test="
                        count($raw-texts) eq 2 and (every $i in $raw-texts
                            satisfies matches($i, '\S'))">
                    <xsl:sequence select="tan:replace-diff($raw-texts[1], $raw-texts[2], .)"/>
                </xsl:when>
                <xsl:when
                    test="
                        some $i in $raw-texts
                            satisfies string-length($i) gt 0">
                    <xsl:message
                        select="'The following ' || string(count($raw-texts)) || ' raw texts cannot be used to replace the original diff: ' || string-join($raw-texts, ' || ')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-diff'"/>
            <xsl:apply-templates select="$diff-replaced/@*" mode="#current"/>
            <xsl:apply-templates select="$diff-replaced/node()" mode="#current"/>

        </xsl:element>
    </xsl:template>

    <!-- HTML TABLE: for comparing commonality between pairs of versions -->
    <xsl:template match="tan:group/tan:collation" mode="diff-and-collate-to-html">
        <!-- If $raw-texts is populated, it is a tacit request to replace the collation with the original, 
            raw text for the witness picked. -->
        <xsl:param name="raw-texts" tunnel="yes" as="xs:string*"/>
        <xsl:param name="last-wit-idref" tunnel="yes" as="xs:string?"/>
        
        <xsl:variable name="witness-ids" select="tan:witness/@id"/>
        <xsl:variable name="collation-replaced" as="element()">
            <xsl:choose>
                <xsl:when test="count($raw-texts) eq 1 and string-length($raw-texts) gt 0">
                    <xsl:sequence select="tan:replace-collation($raw-texts, $last-wit-idref, .)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
        <xsl:if test="exists(tan:witness/tan:commonality)">
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
                        <xsl:apply-templates select="tan:witness" mode="#current">
                            <xsl:with-param name="witness-ids" select="$witness-ids"/>
                        </xsl:apply-templates>
                    </tbody>
                </table>
            </div>
        </xsl:if>
        <!-- venns appeared in the previous sibling, but for visualization, it makes sense to study them
        only after looking at the two-way tables, hence the placement of the template invocation here. -->
        <xsl:apply-templates select="../tan:stats/tan:venns" mode="#current"/>
        <!-- The following processes the a, b, u, common elements -->
        <h2 xmlns="http://www.w3.org/1999/xhtml">Comparison</h2>
        <!-- The raw output of tan:collate() leaves witnesses and u/c elements as siblings, when they
        should be considered two separate parts. This wraps the u/c elements in their own container. 
        (The output for tan:diff() doesn't need this, because a/b/commons are already wrapped, and don't
        need to be distinguished from non-output.) -->
        <div xmlns="http://www.w3.org/1999/xhtml" class="collation">
            <xsl:apply-templates select="$collation-replaced/(* except tan:witness)" mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:witness" mode="diff-and-collate-to-html">
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

    <xsl:template match="*" mode="diff-and-collate-to-html">
        <xsl:param name="last-wit-idref" tunnel="yes"/>
        <xsl:param name="diff-a-ref" tunnel="yes" as="xs:string?" select="@ref"/>
        <xsl:param name="diff-b-ref" tunnel="yes" as="xs:string?" select="@ref"/>
        
        <xsl:variable name="these-ws" select="tan:wit/@ref"/>
        <xsl:variable name="this-w-count" select="ancestor::tan:group/@count"/>
        <xsl:variable name="these-w-class-vals"
            select="
            string-join(for $i in $these-ws
            return
            ' a-w-' || $i)"
        />
        <!-- For tan:collate() 2.0 results, which supplies @base for a likely base version -->
        <xsl:variable name="this-base-class-val"
            select="
                if (exists(@base)) then
                    ' a-base'
                else
                    ()"
        />
        <!--<xsl:variable name="this-special-class-val"
            select="
                if (($these-ws = $last-wit-idref) or self::tan:b) then
                    ' a-last a-other'
                else
                    ()"
        />-->
        <xsl:variable name="this-special-class-val" as="xs:string*">
            <!-- If a diff, we add last and other if the diff-a or diff-b reference has been marked as last;
            if there is no match, then diff-b is the default last/other item. -->
            <!-- If a collation, we add last and other only if there is a witness marked as the last. -->
            <xsl:if test="(self::tan:a and $diff-a-ref = $last-wit-idref)
                or (self::tan:b and (string-length($diff-a-ref) lt 1))
                or ($these-ws = $last-wit-idref)">
                <xsl:value-of select="' a-last a-other'"/>
            </xsl:if>
        </xsl:variable>
        <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'e-' || name(.) || $these-w-class-vals || $this-base-class-val || $this-special-class-val"/>
            
            <xsl:choose>
                <xsl:when test="exists(tan:wit)">
                    <!-- Based on results of tan:collate() 3.0 -->
                    <div class="wits" xmlns="http://www.w3.org/1999/xhtml">
                        <xsl:value-of select="string-join(tan:wit/@ref, ' ')"/>
                    </div>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:when>
                <xsl:when test="exists(@w)">
                    <!-- Based on results of tan:collate() 2.0 -->
                    <div class="wits" xmlns="http://www.w3.org/1999/xhtml">
                        <xsl:value-of select="@w"/>
                    </div>
                    <div class="text" xmlns="http://www.w3.org/1999/xhtml">
                        <xsl:apply-templates select="@* | node()" mode="#current"/>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:element>
    </xsl:template>
    
    <!-- We skip <wit> since they've been amalgamated as a new first child of the parent  -->
    <xsl:template match="tan:wit" mode="diff-and-collate-to-html"/>
    <xsl:template match="tan:notices/*[not(tan:message)]" priority="1"
        mode="diff-and-collate-to-html"/>
    
    <xsl:template match="tan:notices | tan:notices/*" mode="diff-and-collate-to-html">
        <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'a-' || name(.)"/>
            <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="class" select="'label'"/>
                <xsl:copy-of select="tan:text-to-html-for-compare-app(name(.))"/>
            </xsl:element>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="@*" mode="diff-and-collate-to-html">
        <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="class" select="'a-' || name(.)"/>
            <xsl:copy-of select="tan:text-to-html-for-compare-app(.)"/>
        </xsl:element>
    </xsl:template>
    <!-- parse the witnesses as individual classes only in the host element -->
    <xsl:template match="@w | @base | @length | @_pos | @_len" mode="diff-and-collate-to-html"/>
    
    
    <xsl:function name="tan:text-to-html-for-compare-app" as="item()*">
        <!-- Input: a string -->
        <!-- Output: the string parsed for html content, for this application -->
        <xsl:param name="input-string" as="xs:string?"/>
        <xsl:analyze-string select="$input-string" regex="\r?\n">
            <xsl:matching-substring>
                <xsl:text>¶</xsl:text>
                <xsl:element name="br" namespace="http://www.w3.org/1999/xhtml"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:analyze-string select="." regex="(file|https?|ftp)://?\S+">
                    <xsl:matching-substring>
                        <!-- Pull back from any characters at the end that aren't part of the URL proper. -->
                        <xsl:analyze-string select="." regex="(&lt;[^&gt;]+&gt;|[&lt;\)\].;])+$">
                            <xsl:matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:variable name="href-norm" select="replace(., '\.$', '')"/>
                                <a href="{$href-norm}" xmlns="http://www.w3.org/1999/xhtml">
                                    <xsl:value-of select="."/>
                                </a>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:template match="text()" mode="diff-and-collate-to-html">
        <xsl:copy-of select="tan:text-to-html-for-compare-app(.)"/>
    </xsl:template>
    


</xsl:stylesheet>
