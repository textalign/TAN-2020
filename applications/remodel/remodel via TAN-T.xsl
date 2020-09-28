<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Catalyzing (main) input: a class 1 TAN file -->
    <!-- Secondary input: a TAN-T(EI) that exemplifies a model reference system that 
        the input should imitate -->
    <!-- Primary output: the original catalyzing input, but with the text infused into the 
        <div> structure of the model. The text allocated to the new <div> structure proportionate 
        to the text length in the model. -->
    
    <!-- This application is intended to help users wholly restructure their texts. -->
    <!-- The output will likely be imperfect, and will require further editing. See suggestions below. -->

    <!-- The catalyzing input should be a TAN-T(EI) file, perhaps with one <div> with the entire text.
        If the input is not TAN, then there is no way for the algorithm to determine the correct metadata 
        for the output file. Errors are likely. -->
    
    
    <!-- Here are some ways to use this application:
    
    Method: gentle increments
    1. Run plain text against the model.
    2. Edit the output, focusing only on getting the top-level divisions correct.
    3. Change the parameter $preserve-matching-ref-structures-up-to-what-level to 1.
    4. Run the edited input against the model again. Your top-level divisions should remain intact.
    5. Edit the output, focusing only on getting the 2nd-level divisions correct.
    6. Repeat ##3-5 through the rest of the hierarchy.
    Use this method in tandem with the TAN editing tools in Oxygen, where you can easily push and pull
    entire words, clauses, and sentences from one leaf div to another. When you are editing (##2, 5),
    place the model in a parallel window.
    
    Method: complete the square
    Sometimes you have a model text in version A that is in two different reference systems (A1 and A2). 
    You now want to work on version B, and set up TAN-T(EI) versions in both reference systems (B1 and B2).
    1. Apply the gentle increments method to version B on ref system 1.
    2. Make sure that A1 and A2 point to each other through mutual <redivision>s.
    3. Add to version B1 a <model> that points to A1.
    4. Run B1 against A2 with this application. It will check to see if there is an intermediate version
    (A1) against which it can more precisely calibrate the portions of B1.
    5. Edit B2 along the lines discussed under gentle increments.
    The method is called complete the square, because #4 assumes this:
    A1   A2
    B1  [  ]
    The version A1 becomes instrumental in making its catacorner counterpart more accurate. This method 
    was first introduced in the stable 2020 application, but as of Sept. 2020, when a major revision was 
    undertaken, the complete the square method has not been implemented. When it is, the implementation 
    will likely be placed at step 2, to calibrate the fulcrum decimal key for each fragment.
    
    Working with non-XML input
    You might have text from some non-XML source that you want to feed into this method. If you can get
    down to the plain text, then you can run another process before this one. Get a copy of the model, 
    and infuse the plain text into a single <div>. Now run that altered model against the original 
    model. You'll need to do a lot of metadata editing, but at least you'll have a good start on getting
    the body structured. -->
    
    
    <!-- Please note: if you remodel a set of leaf divs that are siblings, and there are intervening
    divs that are not being remodeled, the entire remodel will be placed at the location of the first
    sibling only. That is, that area of the remodel will be consolidated, and the text will no longer
    reflect the original order. -->

    <xsl:param name="output-diagnostics-on" static="yes" select="false()"/>

    <xsl:import href="../get%20inclusions/xslt-for-docx/open-and-save-archive.xsl"/>
    <xsl:import href="../../functions/TAN-T-functions.xsl"/>
    <xsl:import href="../../functions/TAN-extra-functions.xsl"/>
    <xsl:import href="../get%20inclusions/core-for-TAN-output.xsl"/>
    
    <xsl:output indent="yes" use-when="$output-diagnostics-on"/>
    
    <xsl:param name="validation-phase" select="'terse'"/>

    <!-- PARAMETERS YOU WILL WANT TO CHANGE MOST OFTEN -->

    <!-- What top-level divs should be excluded (kept intact) from the input? Expected: a regular expression matching @n. If blank, this has no effect. -->
    <xsl:param name="exclude-from-input-top-level-divs-with-attr-n-matching-what" as="xs:string?" select="''"/>
    
    <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type. If blank, this has no effect. -->
    <xsl:param name="exclude-from-input-divs-with-attr-type-matching-what" as="xs:string?" select="''"/>

    <!-- At what level should remodeling begin? Suppose you have a file that preserves only the topmost hierarchy of its model, and you want to subdivide further. By setting this value to 1 or greater, you can try to preserve matching structures, and focus the remodeling on individual instances. If any <div> in the input does not match at that level, it will be exempt from the remodelling. -->
    <xsl:param name="preserve-matching-ref-structures-up-to-what-level" as="xs:integer?" select="1"/>
    
    <!-- Does the model have a scriptum-oriented reference system or a logical one? -->
    <xsl:param name="model-has-scriptum-oriented-reference-system" as="xs:boolean" select="false()"/>

    <!-- What regular expression should be used to define the end of a sentence? -->
    <xsl:param name="sentence-end-regex" select="'[\.;\?!ا·*]+[\p{P}\s]*'"/>
    
    <!-- What regular expression should be used to define the end of a clause? -->
    <xsl:param name="clause-end-regex" select="'\w\p{P}+\s*'"/>
    
    <!-- What regular expression should be used to decide where breaks are allowed if the model has a scriptum-based structure? -->
    <xsl:param name="break-at-regex-for-scriptum-oriented-divs" as="xs:string"
        select="$word-end-regex"/>
    
    <!-- What regular expression should be used to decide where breaks are allowed if the model has a logical (non-scriptum) reference system? -->
    <!-- In the following, you might want to use $clause-end-regex; if the transcription has little punctuation, $word-end-regex -->
    <xsl:param name="break-at-regex-for-logical-oriented-divs" as="xs:string"
        select="$clause-end-regex"/>
    
    <!-- What regular expression should be used to break the text in the input? By default, the choice is made depending on whether the input source is scriptum-oriented or not. -->
    <xsl:param name="break-at-regex"
        select="
            if ($model-has-scriptum-oriented-reference-system) then
                $break-at-regex-for-scriptum-oriented-divs
            else
                $break-at-regex-for-logical-oriented-divs"
    />
    
    <!-- If chopping up segments of text, should parenthetical clauses be preserved intact? -->
    <xsl:param name="do-not-chop-parenthetical-clauses" as="xs:boolean" select="false()"/>

    <!-- Where is the model relative to the catalyzing input? Default is the @href for the first <model> within the input file. -->
    <xsl:param name="model-uri-relative-to-catalyzing-input" as="xs:string?"
        select="/*/tan:head/tan:model[1]/tan:location[1]/@href"/>

    <!-- What top-level divs should be excluded (kept intact) from the input? Expected: a regular expression matching @n. If blank, this has no effect. -->
    <xsl:param name="exclude-from-model-top-level-divs-with-attr-n-matching-what" as="xs:string?"/>
    
    <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type. If blank, this has no effect. -->
    <xsl:param name="exclude-from-model-divs-with-attr-type-matching-what" as="xs:string?" select="'title'"/>
    
    

    <!-- Parameters normalized -->
    <!-- We call the model the current model to distinguish it more clearly from TAN global variables referring to a document's model (which may differ from the model being used here). -->
    <xsl:variable name="current-model-uri-resolved"
        select="resolve-uri($model-uri-relative-to-catalyzing-input, $doc-uri)"/>
    <xsl:variable name="check-attr-type" as="xs:boolean" select="string-length($exclude-from-input-divs-with-attr-type-matching-what) gt 0"/>
    <xsl:variable name="check-top-attr-n" as="xs:boolean" select="string-length($exclude-from-input-top-level-divs-with-attr-n-matching-what) gt 0"/>
    <xsl:variable name="check-div-level" as="xs:boolean" select="$preserve-matching-ref-structures-up-to-what-level gt 0"/>


    <!-- THIS STYLESHEET -->

    <xsl:param name="stylesheet-name" select="'TAN remodeler'"/>
    <xsl:param name="stylesheet-iri" select="'tag:textalign.net,2015:stylesheet:remodel-via-tan-t'"/>
    <xsl:variable name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="change-message">
        <xsl:text>Input from </xsl:text>
        <xsl:value-of select="base-uri(/)"/>
        <xsl:text> proportionally remodeled after template at </xsl:text>
        <xsl:value-of select="$current-model-uri-resolved"/>
    </xsl:param>
    
    <!-- STEP 1: MARK DIVS THAT SHOULD BE REMODELED -->
    <!-- We set @_remodel in the appropriate <div> to make it easy to do a substitute in the original based on @q values. -->

    <xsl:variable name="current-model-doc" select="tan:open-file($current-model-uri-resolved)"/>
    <xsl:variable name="current-model-doc-resolved" select="tan:resolve-doc($current-model-doc)"/>
    <xsl:variable name="current-model-doc-expanded" select="tan:expand-doc($current-model-doc-resolved)"/>
    <xsl:variable name="current-model-doc-expanded-and-pruned" as="document-node()?">
        <xsl:apply-templates select="$current-model-doc-expanded" mode="prune-model-doc"/>
    </xsl:variable>
    <xsl:template match="tan:div" mode="prune-model-doc">
       <xsl:choose>
            <xsl:when
                test="
                    parent::tan:body
                    and (string-length($exclude-from-model-top-level-divs-with-attr-n-matching-what) gt 0)
                    and matches(@n, $exclude-from-model-top-level-divs-with-attr-n-matching-what)"
            />
            <xsl:when
                test="
                    string-length($exclude-from-model-divs-with-attr-type-matching-what) gt 0
                    and matches(@type, $exclude-from-model-divs-with-attr-type-matching-what)"
            />
           <xsl:otherwise>
               <xsl:copy>
                   <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
               </xsl:copy>
           </xsl:otherwise>
       </xsl:choose> 
    </xsl:template>

    <xsl:variable name="input-marked" as="document-node()">
        <xsl:apply-templates select="$self-expanded" mode="mark-input"/>
    </xsl:variable>
    
    <xsl:template match="tan:div" mode="mark-input">
        <xsl:variable name="this-n" select="@n"/>
        <xsl:variable name="this-type" select="@type"/>
        <xsl:variable name="this-level" select="count(ancestor-or-self::*:div)"/>
        <xsl:variable name="is-top-level-div" select="$this-level eq 1"/>
        <xsl:variable name="deep-copy-this-div" as="xs:boolean">
            <xsl:choose>
                <xsl:when test="$check-attr-type and matches($this-type, $exclude-from-input-divs-with-attr-type-matching-what)">
                    <xsl:sequence select="true()"/>
                </xsl:when>
                <xsl:when test="$is-top-level-div and $check-top-attr-n and matches($this-n, $exclude-from-input-top-level-divs-with-attr-n-matching-what)">
                    <xsl:sequence select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="wrap-this-leaf-div-text"
            select="not(tan:div) and ($this-level eq $preserve-matching-ref-structures-up-to-what-level)"
        />
        <xsl:variable name="shallow-copy-this-div"
            select="$check-div-level and $this-level le $preserve-matching-ref-structures-up-to-what-level"
        />
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode mark-input'"/>
            <xsl:message select="'This ref: ' || tan:ref[1]/text()"/>
            <xsl:message select="'Is top level div:', $is-top-level-div"/>
            <xsl:message select="'Check top divs for attr n?', $check-top-attr-n"/>
            <xsl:message select="'Deep copy this div?', $deep-copy-this-div"/>
            <xsl:message select="'Shallow copy this div?', $shallow-copy-this-div"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="$deep-copy-this-div">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="$wrap-this-leaf-div-text">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="tan:n | tan:ref"/>
                    <div _remodel="">
                        <xsl:value-of select="string-join(descendant-or-self::tan:div/text())"/>
                    </div>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$shallow-copy-this-div">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="_remodel"/>
                    <xsl:copy-of select="tan:n | tan:ref"/>
                    <xsl:value-of select="string-join(descendant-or-self::tan:div/text())"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- STEP 2: BUILD A MAP OF MAPS, EACH A LIST OF DECIMALS PLUS A CORRESPONDING TEXT  -->
    <!-- Each top-level map entry has as its key the reference of the wrapping <body> or <div>, so that adjacent 
        replacements can be handled together. The content of the map is itself a map of with each map entry
        consisting of a decimal key and a string. The decimal, between zero and 1, represents how far along 
        in the <div> the phrase is occurs, based in its fulcrum (midpoint of the string) -->
    
    <xsl:variable name="remodel-maps" as="map(xs:string, map(*))">
        <xsl:map>
            <xsl:apply-templates select="$input-marked/tan:TAN-T/tan:body" mode="build-remodel-map"/>
        </xsl:map>
    </xsl:variable>
    
    <xsl:template match="* | comment() | text() | document-node() | processing-instruction()"
        mode="build-remodel-map">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*[*[@_remodel]]" priority="1" mode="build-remodel-map">
        <xsl:variable name="this-ref"
            select="
                if (self::tan:body) then
                    '#root'
                else
                    tan:ref[1]/text()"/>
        <xsl:variable name="this-string" select="string-join(*[@_remodel]/text())"/>
        <xsl:variable name="this-string-chopped"
            select="tan:chop-string($this-string, $break-at-regex, $do-not-chop-parenthetical-clauses)"/>
        <xsl:variable name="this-string-length" select="string-length($this-string)"/>
        <xsl:variable name="this-remodel-map" as="map(xs:decimal, xs:string)">
            <xsl:map>
                <xsl:iterate select="$this-string-chopped">
                    <xsl:param name="next-pos" select="1"/>
                    <xsl:variable name="this-len" select="string-length(.)"/>
                    <xsl:variable name="this-fulcrum" select="(($this-len div 2) + $next-pos) div $this-string-length"/>
                    <xsl:map-entry key="xs:decimal($this-fulcrum)" select="."/>
                    <xsl:next-iteration>
                        <xsl:with-param name="next-pos" select="$next-pos + $this-len"/>
                    </xsl:next-iteration>
                </xsl:iterate>
            </xsl:map>
        </xsl:variable>
        <xsl:map-entry key="xs:string($this-ref)" select="$this-remodel-map"/>

    </xsl:template>
    
    
    <!-- STEP 3: APPLY EACH MAP LOCALLY TO SPECIFIC PARTS OF THE MODEL -->
    <!-- If a <body> or <div> is encountered with a reference that matches a map, a localized reapportioning
    takes place. The wrapper is given @_replacement to signal that the input can be reinjected. -->

    <xsl:variable name="model-infused-pass-1" as="document-node()?">
        <xsl:apply-templates select="$current-model-doc-expanded-and-pruned" mode="infuse-model"/>
    </xsl:variable>
    
    <xsl:template match="tan:body | tan:div" mode="infuse-model">
        <xsl:variable name="wraps-what-level" select="count(ancestor-or-self::tan:div) + 1"/>
        <xsl:variable name="these-refs"
            select="
                if (self::tan:body) then
                    '#root'
                else
                    tan:ref/text()"
        />
        <xsl:variable name="corresponding-remodel-map"
            select="
                for $i in $these-refs
                return
                    map:get($remodel-maps, $i)"
            as="map(xs:decimal, xs:string)*"/>
        
        <xsl:if test="count($corresponding-remodel-map) gt 1">
            <xsl:message
                select="'Found', count($corresponding-remodel-map), 'maps. Only the first will be processed.'"
            />
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when
                    test="$check-div-level and $wraps-what-level le $preserve-matching-ref-structures-up-to-what-level">
                    <xsl:apply-templates mode="#current"/>
                </xsl:when>
                <!-- If it's a leaf div, no further remodeling can be done, so just drop in the text -->
                <xsl:when test="exists($corresponding-remodel-map) and not(tan:div)">
                    <xsl:variable name="remodel-map-keys" select="map:keys($corresponding-remodel-map[1])"/>
                    <xsl:variable name="these-texts"
                        select="
                            for $i in sort($remodel-map-keys)
                            return
                                map:get($corresponding-remodel-map[1], $i)"
                    />
                    
                    <xsl:message select="'Request has been made to remodel text at ' || string-join($these-refs, ', ') || ' but the model has no subdivisions against which the input can be remodeled.'"/>
                    
                    <xsl:attribute name="_replacement"/>
                    
                    <xsl:if test="self::tan:body">
                        <ref>#root</ref>
                    </xsl:if>
                    
                    <xsl:copy-of select="* except tei:*"/>
                    <xsl:value-of select="string-join($these-texts)"/>
                </xsl:when>
                <xsl:when test="exists($corresponding-remodel-map)">
                    <xsl:variable name="self-marked"
                        select="tan:stamp-tree-with-text-data(., true())"/>
                    <xsl:variable name="self-marked-proportionately" as="element()">
                        <xsl:apply-templates select="$self-marked"
                            mode="_pos-and-_len-ints-to-portions">
                            <xsl:with-param name="length" as="xs:integer"
                                select="xs:integer($self-marked/@_len)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:attribute name="_replacement"/>

                    <xsl:if test="self::tan:body">
                        <ref>#root</ref>
                    </xsl:if>

                    <xsl:apply-templates select="$self-marked-proportionately/*"
                        mode="apply-remodel-content">
                        <xsl:with-param name="remodel-map" tunnel="yes"
                            select="$corresponding-remodel-map[1]"/>
                        <xsl:with-param name="remodel-map-keys" tunnel="yes"
                            select="map:keys($corresponding-remodel-map[1])"/>
                    </xsl:apply-templates>


                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*[@_pos] | *[@_len]" mode="_pos-and-_len-ints-to-portions">
        <xsl:param name="length" as="xs:integer" tunnel="yes"/>
        <xsl:variable name="this-pos" select="xs:integer(@_pos)"/>
        <xsl:variable name="this-len" select="xs:integer(@_len)"/>
        <xsl:variable name="this-sum" select="$this-pos + $this-len"/>
        <xsl:variable name="this-start" select="if ($this-pos eq 1) then xs:decimal(0) else $this-pos div $length"/>
        <xsl:variable name="this-end" select="if ($this-sum eq $length) then xs:decimal(1) else $this-sum div $length"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="_start" select="$this-start"/>
            <xsl:attribute name="_end" select="$this-end"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:div[not(tan:div)][@_start]" mode="apply-remodel-content">
        <xsl:param name="remodel-map" tunnel="yes" as="map(xs:decimal, xs:string)?"/>
        <xsl:param name="remodel-map-keys" tunnel="yes" as="xs:decimal*"/>
        <xsl:variable name="this-start" select="number(@_start)"/>
        <xsl:variable name="this-end" select="number(@_end)"/>
        <xsl:variable name="these-keys" select="$remodel-map-keys[(. gt $this-start) and (. le $this-end)]"/>
        <xsl:variable name="these-texts" select="for $i in sort($these-keys) return map:get($remodel-map, $i)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="* except tei:*"/>
            <xsl:value-of select="string-join($these-texts)"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- STEP 4: INJECT REMODELLED SECTIONS INTO INPUT -->
    
    <xsl:variable name="input-with-replacements" as="document-node()">
        <xsl:apply-templates select="/" mode="reinject-remodeled-sections">
            <xsl:with-param name="is-tei" select="exists(tei:*)" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:template match="*:div" mode="reinject-remodeled-sections">
        <xsl:param name="is-tei" tunnel="yes" as="xs:boolean" select="false()"/>
        
        <xsl:variable name="this-q" select="generate-id()"/>
        <xsl:variable name="matching-marked-input-item" select="key('q-ref', $this-q, $input-marked)"/>
        <xsl:variable name="this-has-been-remodeled" select="exists($matching-marked-input-item/@_remodel)"/>
        <xsl:variable name="this-text-has-been-remodeled" select="exists($matching-marked-input-item/tan:div[@_remodel][not(@n)])"/>
        <xsl:variable name="matching-item-is-first-sibling" select="not(exists($matching-marked-input-item/preceding-sibling::*[@_remodel]))"/>
        <!-- Matching items are sought at the parental level, to fetch the siblings' replacements too. -->
        <xsl:variable name="matching-item-refs"
            select="
                if ($this-text-has-been-remodeled) then
                    $matching-marked-input-item/tan:ref/text()
                else
                    if ($matching-marked-input-item/parent::tan:body) then
                        '#root'
                    else
                        $matching-marked-input-item/parent::tan:div/tan:ref/text()"
        />
        <xsl:variable name="matching-remodeled-substitutes"
            select="
                if ($matching-item-refs = '#root')
                then
                    $model-infused-pass-1/*/tan:body
                else
                    key('div-via-ref', $matching-item-refs, $model-infused-pass-1)"
        />
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode reinject-remodeled-sections'"/>
            <xsl:message select="'This ref: ' || string-join(ancestor-or-self::*/@n, ' ')"/>
            <xsl:message select="'Matching marked input item: ', $matching-marked-input-item"/>
            <xsl:message select="'This element has been remodeled: ', $this-has-been-remodeled"/>
            <xsl:message select="'This text has been remodeled: ', $this-text-has-been-remodeled"/>
            <xsl:message select="'Matching item is first sibling:', $matching-item-is-first-sibling"/>
            <xsl:message select="'Matching item refs: ' || string-join($matching-item-refs, ', ')"/>
            <xsl:message select="'Matching remodeled substitutes (shallow copy): ', tan:shallow-copy($matching-remodeled-substitutes, 2)"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="$this-has-been-remodeled and $matching-item-is-first-sibling and $is-tei">
                <xsl:variable name="these-substitutes" as="element()*">
                    <substitutes>
                        <xsl:apply-templates select="$matching-remodeled-substitutes/*"
                            mode="clean-up-remodel-for-tei"/>
                    </substitutes>
                </xsl:variable>
                <xsl:copy-of select="tan:copy-indentation($these-substitutes/*, .)"/>
            </xsl:when>
            <xsl:when test="$this-has-been-remodeled and $matching-item-is-first-sibling">
                <xsl:variable name="these-substitutes" as="element()*">
                    <substitutes>
                        <xsl:apply-templates select="$matching-remodeled-substitutes/*"
                            mode="clean-up-remodel-for-tan"/>
                    </substitutes>
                </xsl:variable>
                <xsl:copy-of select="tan:copy-indentation($these-substitutes/*, .)"/>
            </xsl:when>
            <xsl:when test="$this-has-been-remodeled and not(exists($matching-remodeled-substitutes)) and $is-tei">
                <xsl:copy-of select="tan:normalize-tan-tei-divs(., false())"/>
            </xsl:when>
            <xsl:when test="$this-has-been-remodeled and not(exists($matching-remodeled-substitutes))">
                <xsl:copy-of select="."/>
            </xsl:when>
            <!-- If its not the first sibling, it gets skipped, because the remodels are pegged to only the first sibling -->
            <xsl:when test="$this-has-been-remodeled">
                <skip/>
            </xsl:when>
            <xsl:when test="$this-text-has-been-remodeled and not(exists($matching-remodeled-substitutes)) and $is-tei">
                <xsl:copy-of select="tan:normalize-tan-tei-divs(., false())"/>
                <!--<xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="_preserved" select="$this-q"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>-->
            </xsl:when>
            <xsl:when test="$this-text-has-been-remodeled and not(exists($matching-remodeled-substitutes))">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="$this-text-has-been-remodeled and $is-tei">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="$matching-remodeled-substitutes/node()"
                        mode="clean-up-remodel-for-tei"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="$this-text-has-been-remodeled">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="$matching-remodeled-substitutes/node()"
                        mode="clean-up-remodel-for-tan"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="* | text()" mode="clean-up-remodel-for-tan clean-up-remodel-for-tei">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="tan:div" mode="clean-up-remodel-for-tan">
        <xsl:copy>
            <xsl:copy-of select="@n | @type | @ed-when | @ed-who | @xml:lang"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:div/text()" priority="1" mode="clean-up-remodel-for-tan">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="tan:div[tan:div]" mode="clean-up-remodel-for-tei">
        <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@*[not(starts-with(name(.), '_'))] except @q"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tan:div[not(tan:div)]" mode="clean-up-remodel-for-tei">
        <xsl:element name="div" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@*[not(starts-with(name(.), '_'))] except @q"/>
            <!-- We set it as an anonymous block, because no doubt the internal markup has been greatly disrupted. -->
            <xsl:element name="ab" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:value-of select="text()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tan:div[not(tan:div)]/text()" mode="clean-up-remodel-for-tei">
        <!-- If the infusion is simple text, it should be wrapped in a tei:ab -->
        <xsl:element name="ab" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <!-- Step 4b for TEI files: try to reinject empty (anchor) elements into the new results. The strategy:
    1. get a TEI <body> with <div>s space-normalized;
    2. calculate the string position of each child element;
    3. calculate the string position of the new results;
    4. infuse #2 into #3 -->
    
    <xsl:variable name="input-tei-body-normalized" as="element()?" select="tan:normalize-tan-tei-divs(/tei:TEI/tei:text/tei:body, false())"/>
    
    <xsl:variable name="input-tei-body-normalized-and-marked" as="element()?"
        select="tan:stamp-tree-with-text-data($input-tei-body-normalized, true(), (), (), 1)"
    />
    
    <xsl:variable name="replaced-tei-body-marked" as="element()?"
        select="tan:stamp-tree-with-text-data($input-with-replacements/tei:TEI/tei:text/tei:body, true(), (), (), 1)"
    />
    
    <!-- for testing, diagnostics -->
    <xsl:variable name="two-tei-texts-compared" select="tan:diff(string-join($input-tei-body-normalized-and-marked//tei:div[not(tei:div)]), string-join($replaced-tei-body-marked//tei:ab))"/>
    
    
    <xsl:variable name="original-tei-div-children-elements" select="$input-tei-body-normalized-and-marked//tei:div[not(tei:div)]/*"/>
    
    <xsl:variable name="replaced-tei-body-infused-with-original-div-descedant-elements" as="element()?">
        <xsl:apply-templates select="$replaced-tei-body-marked" mode="remold-tei-leaf-divs">
            <xsl:with-param name="marked-tei-leaf-div-children" tunnel="yes" select="$original-tei-div-children-elements"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:template match="tei:body | tei:div[tei:div]" mode="remold-tei-leaf-divs">
        <xsl:copy>
            <xsl:copy-of select="@* except (@_pos | @_len)"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:div[not(tei:div)]" mode="remold-tei-leaf-divs">
        <xsl:param name="marked-tei-leaf-div-children" tunnel="yes" as="element()*"/>
        <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
        <xsl:variable name="this-length" select="xs:integer(@_len)"/>
        <xsl:variable name="this-end" select="$this-start + $this-length - 1"/>
        <xsl:variable name="relevant-new-children" select="$marked-tei-leaf-div-children[xs:integer(@_pos) le $this-end][(xs:integer(@_pos) + xs:integer(@_len)) gt $this-start]"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode remold-tei-leaf-divs, on ' || serialize(tan:shallow-copy(.))"/>
            <xsl:message select="'Start, length: ' || @_pos || ' ' || @_len"/>
            <xsl:message select="'Marked tei leaf div children count: ' || string(count($marked-tei-leaf-div-children))"/>
            <xsl:message select="'Relevant new-children: ' || serialize(tan:shallow-copy($relevant-new-children))"/>
        </xsl:if>

        <xsl:copy>
            <xsl:copy-of select="@* except (@_pos | @_len | @_level)"/>
            <xsl:apply-templates select="$relevant-new-children" mode="infuse-new-tei-mold">
                <xsl:with-param name="text-to-infuse" tunnel="yes" select="string(.)"/>
                <xsl:with-param name="text-starting-pos" as="xs:integer" tunnel="yes" select="$this-start"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*" mode="infuse-new-tei-mold">
        <xsl:param name="text-to-infuse" tunnel="yes" as="xs:string?"/>
        <xsl:param name="text-starting-pos" as="xs:integer" tunnel="yes"/>
        
        <xsl:param name="text-infusion-end-pos" select="$text-starting-pos + string-length($text-to-infuse)"/>
        
        <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
        <xsl:variable name="this-len" select="xs:integer(@_len)"/>
        <xsl:variable name="this-text-substring" select="substring($text-to-infuse, ($this-start - $text-starting-pos + 1), $this-len)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode infuse-new-tei-mold, on ' || tan:shallow-copy(.)"/>
            <xsl:message select="'Text to infuse: ' || $text-to-infuse"/>
            <xsl:message select="'Text starting, ending position: ' || string($text-starting-pos) || ' ' || string($text-infusion-end-pos)"/>
            <xsl:message select="'This mold start: ' || @_pos"/>
            <xsl:message select="'This mold length: ' || @_len"/>
            <xsl:message select="'Picked text substring: ' || $this-text-substring"/>
        </xsl:if>
        
        <xsl:copy>
            <xsl:copy-of select="@* except (@_pos | @_len | @_level)"/>
            <xsl:if test="not(exists(node()))">
                <xsl:value-of select="$this-text-substring"/>
            </xsl:if>
            <xsl:iterate select="node()">
                <xsl:param name="next-start" as="xs:integer" select="$this-start"/>
                <xsl:variable name="this-seg-len"
                    select="
                        if (exists(@_len)) then
                            xs:integer(@_len)
                        else
                            string-length(.)"
                />
                <xsl:variable name="next-next-start" select="$next-start + $this-seg-len"/>
                <xsl:variable name="this-overlaps-with-text-to-infuse"
                    select="(($next-start lt $text-infusion-end-pos) and ($next-start ge $text-starting-pos))
                    or ($next-next-start le $text-infusion-end-pos) and ($next-next-start gt $text-starting-pos)
                    or (($next-start lt $text-starting-pos) and ($next-next-start gt $text-infusion-end-pos))"/>
                <xsl:variable name="this-text-segment" select="substring($text-to-infuse, ($next-start - $text-starting-pos + 1), $this-seg-len)"/>
                
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'This item: ', ."/>
                    <xsl:message select="'Start pos: ' || string($next-start)"/>
                    <xsl:message select="'This seg length: ' || string($this-seg-len)"/>
                    <xsl:message select="'This overlaps with text to infuse?', $this-overlaps-with-text-to-infuse"/>
                    <xsl:message select="'This text fragment: ' || $this-text-segment"/>
                </xsl:if>
                
                <xsl:choose>
                    <xsl:when test="not($this-overlaps-with-text-to-infuse)"/>
                    <xsl:when test=". instance of text()">
                        <xsl:value-of select="$this-text-segment"/>
                    </xsl:when>
                    <xsl:when test=". instance of element()">
                        <xsl:apply-templates select="." mode="#current">
                            <xsl:with-param name="text-to-infuse" tunnel="yes" select="$this-text-segment"/>
                            <xsl:with-param name="text-starting-pos" as="xs:integer" tunnel="yes" select="$next-start"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:next-iteration>
                    <xsl:with-param name="next-start" select="$next-next-start"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="input-with-replacements-revised" as="document-node()">
        <xsl:apply-templates select="$input-with-replacements" mode="revise-input-with-replacements"
        />
    </xsl:variable>
    <xsl:template match="tei:body" mode="revise-input-with-replacements">
        <xsl:choose>
            <xsl:when test="exists($replaced-tei-body-infused-with-original-div-descedant-elements)">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="$replaced-tei-body-infused-with-original-div-descedant-elements/node()" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Expected to replace the TEI body with a remolded version, not to be found. Diagnose and fix.'"/>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:div[not(matches(., '\S'))]" mode="revise-input-with-replacements"/>
    
    
    <!-- STEP 5: CLEAN UP RESULTS -->
    
    <xsl:variable name="results-cleaned" as="document-node()">
        <xsl:apply-templates select="$input-with-replacements-revised" mode="clean-results"/>
    </xsl:variable>
    
    <xsl:variable name="new-head-linking-elements" as="element()+">
        <xsl:if test="not($current-model-doc/*/@id = $model-resolved/*/@id)">
            <model>
            <IRI>
                <xsl:value-of select="$current-model-doc/*/@id"/>
            </IRI>
            <xsl:copy-of select="$current-model-doc/*/tan:head/(tan:name | tan:desc)"/>
            <location href="{$model-uri-relative-to-catalyzing-input}"
                accessed-when="{current-date()}"/>
        </model>
        </xsl:if>
        <redivision>
            <IRI>
                <xsl:value-of select="$doc-id"/>
            </IRI>
            <xsl:copy-of select="/*/tan:head/(tan:name | tan:desc)"/>
            <location href="{tan:cfne($doc-uri)}" accessed-when="{current-date()}"/>
        </redivision>

    </xsl:variable>

    <xsl:template match="/processing-instruction() | /comment() | /*" mode="clean-results">
        <xsl:text>&#xa;</xsl:text>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/text()" mode="clean-results"/>
    
    <xsl:template match="tan:source" mode="clean-results">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
        <xsl:copy-of select="tan:copy-indentation($new-head-linking-elements, ., 'full')"/>
    </xsl:template>
    
    <xsl:template match="*[tan:skip]/text()" mode="clean-results">
        <xsl:if test="not(following-sibling::node()[1]/self::tan:skip)">
            <xsl:value-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:skip" mode="clean-results"/>
    
    
    <!-- STEP 6: CREDIT RESULTS -->
    
    <xsl:variable name="results-credited" as="document-node()">
        <xsl:apply-templates select="$results-cleaned" mode="credit-stylesheet"/>
    </xsl:variable>

    
    <!-- OUTPUT -->

    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message
            select="'Using diagnostic output for application ' || $stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <diagnostics>
            <!--<tei-divs-normalized><xsl:copy-of select="tan:normalize-tan-tei-divs(/, false())"/></tei-divs-normalized>-->
            <!--<input-marked><xsl:copy-of select="$input-marked"/></input-marked>-->
            <!--<remodel-maps><xsl:copy-of select="tan:map-to-xml($remodel-maps)"/></remodel-maps>-->
            <!--<model-infused><xsl:copy-of select="$model-infused-pass-1"/></model-infused>-->
            <!--<input-with-replacements><xsl:copy-of select="$input-with-replacements"/></input-with-replacements>-->
            <!-- special attempt to reinfuse TEI empty elements -->
            <input-tei-body-normalized><xsl:copy-of select="$input-tei-body-normalized"/></input-tei-body-normalized>
            <input-tei-body-normalized-and-marked><xsl:copy-of select="$input-tei-body-normalized-and-marked"/></input-tei-body-normalized-and-marked>
            <replaced-tei-body-marked><xsl:copy-of select="$replaced-tei-body-marked"/></replaced-tei-body-marked>
            <two-tei-texts-compared><xsl:copy-of select="$two-tei-texts-compared"/></two-tei-texts-compared>
            <original-tei-div-children-elements><xsl:copy-of select="$original-tei-div-children-elements"/></original-tei-div-children-elements>
            <replaced-tei-body-infused-with-original-div-descedant-elements><xsl:copy-of select="$replaced-tei-body-infused-with-original-div-descedant-elements"/></replaced-tei-body-infused-with-original-div-descedant-elements>
            <results-cleaned><xsl:copy-of select="$results-cleaned"/></results-cleaned>
            <!--<results-credited><xsl:copy-of select="$results-credited"/></results-credited>-->
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:message select="'Remodeling ' || $doc-uri || ' against ' || $current-model-uri-resolved"/>
        <xsl:if test="$check-attr-type"><xsl:message select="'Excluding input div types matching ' || $exclude-from-input-divs-with-attr-type-matching-what"/></xsl:if>
        <xsl:if test="$check-top-attr-n"><xsl:message select="'Excluding top level input divs with @n matching ' || $exclude-from-input-top-level-divs-with-attr-n-matching-what"/></xsl:if>
        <xsl:if test="$check-div-level"><xsl:message select="'Preserving input div structures up to level ' || xs:string($preserve-matching-ref-structures-up-to-what-level)"/></xsl:if>
        <xsl:message
            select="
                'Model reference system is indicated to be ' || (if ($model-has-scriptum-oriented-reference-system) then
                    'scriptum-oriented'
                else
                    'logical') || '. Allowing breaks only at the end of the following regular expression: ' || $break-at-regex"
        />
        <xsl:if test="string-length($exclude-from-model-divs-with-attr-type-matching-what) gt 0"><xsl:message select="'Excluding model div types matching ' || $exclude-from-model-divs-with-attr-type-matching-what"/></xsl:if>
        <xsl:if test="string-length($exclude-from-model-top-level-divs-with-attr-n-matching-what) gt 0"><xsl:message select="'Excluding top level model divs with @n matching ' || $exclude-from-model-top-level-divs-with-attr-n-matching-what"/></xsl:if>
        <xsl:copy-of select="$results-credited"/>
    </xsl:template>

</xsl:stylesheet>
