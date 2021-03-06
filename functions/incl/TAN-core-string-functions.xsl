<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0">

    <!-- General functions that process strings -->

    <xsl:function name="tan:fill" as="xs:string?">
        <!-- Input: a string, an integer -->
        <!-- Output: a string with the first parameter repeated the number of times specified by the integer -->
        <!-- This function was written to facilitate indentation -->
        <xsl:param name="string-to-fill" as="xs:string?"/>
        <xsl:param name="times-to-repeat" as="xs:integer"/>
        <xsl:variable name="results" as="xs:string*">
            <xsl:for-each select="1 to $times-to-repeat">
                <xsl:value-of select="$string-to-fill"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($results, '')"/>
    </xsl:function>

    <xsl:function name="tan:batch-replace" as="xs:string?">
        <!-- Input: a string, a sequence of <[ANY NAME] pattern="" replacement="" [flags=""]> -->
        <!-- Output: the string, after those replaces are processed in order -->
        <xsl:param name="string-to-replace" as="xs:string?"/>
        <xsl:param name="replace-elements" as="element()*"/>
        <xsl:choose>
            <xsl:when test="not(exists($replace-elements))">
                <xsl:value-of select="$string-to-replace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="new-string"
                    select="
                        if (exists($replace-elements[1]/@flags)) then
                            tan:replace($string-to-replace, $replace-elements[1]/@pattern, $replace-elements[1]/@replacement, $replace-elements[1]/@flags)
                        else
                            tan:replace($string-to-replace, $replace-elements[1]/@pattern, $replace-elements[1]/@replacement)"/>
                <xsl:if test="not($string-to-replace = $new-string) and exists($replace-elements[1]/@message)">
                    <xsl:message select="string($replace-elements[1]/@message)"/>
                </xsl:if>
                <xsl:value-of
                    select="tan:batch-replace($new-string, $replace-elements[position() gt 1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:string-length" as="xs:integer">
        <!-- Input: any string -->
        <!-- Output: the number of characters in the string, as defined by TAN (i.e., modifiers are counted with the preceding base character) -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:copy-of select="count(tan:chop-string($input))"/>
    </xsl:function>

    <xsl:function name="tan:normalize-text" as="xs:string*">
        <!-- one-parameter version of full function below -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:copy-of select="tan:normalize-text($text, false())"/>
    </xsl:function>
    <xsl:function name="tan:normalize-name" as="xs:string*">
        <!-- one-parameter, name-normalizing version of tan:normalize-text() -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:copy-of select="tan:normalize-text($text, true())"/>
    </xsl:function>
    <xsl:function name="tan:normalize-text" as="xs:string*">
        <!-- Input: any sequence of strings; a boolean indicating whether the results should be name-normalized -->
        <!-- Output: that sequence, with each item's space normalized, and removal of any help requested -->
        <!-- In name-normalization, the string is converted to lower-case, and spaces replace hyphens, underscores, and illegal characters. -->
        <!-- Special end div characters are not removed in this operation, nor is tail-end space adjusted according to TAN rules; for that, see tan:normalize-div-text(). -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:param name="treat-as-name-values" as="xs:boolean"/>
        <xsl:for-each select="$text">
            <!-- replace illegal characters with spaces; if a name, render lowercase and replace specially designated characters with spaces -->
            <xsl:variable name="prep-pass-1"
                select="
                    if ($treat-as-name-values = true()) then
                        lower-case(replace(., concat($regex-name-space-characters, '|', $regex-characters-not-permitted), ' '))
                    else
                        replace(., $regex-characters-not-permitted, ' ')"/>
            <!-- delete the help trigger and ensure proper use of modifying characters -->
            <xsl:variable name="prep-pass-2"
                select="
                    if ($treat-as-name-values = true()) then
                        replace($prep-pass-1, concat('\p{M}|', $help-trigger-regex), '')
                    else
                        replace($prep-pass-1, concat('\s+(\p{M})|', $help-trigger-regex), '$1')"/>
            <!-- normalize the results, both for space and for unicode -->
            <xsl:value-of select="normalize-unicode(normalize-space($prep-pass-2))"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="tan:atomize-string" as="xs:string*">
        <!-- alias for tan:-chop-string() -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:copy-of select="tan:chop-string($input)"/>
    </xsl:function>

    <xsl:variable name="char-reg-exp" select="'\P{M}\p{M}*'"/>
    <xsl:param name="do-not-chop-parenthetical-clauses" as="xs:boolean" select="false()"/>
    <xsl:function name="tan:chop-string" as="xs:string*">
        <!-- Input: any string -->
        <!-- Output: that string chopped into a sequence of individual characters, following TAN rules (modifying characters always join their preceding base character) -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:if test="string-length($input) gt 0">
            <xsl:analyze-string select="$input" regex="{$char-reg-exp}">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:if>
    </xsl:function>
    <xsl:function name="tan:chop-string" as="xs:string*">
        <!-- 2-param version of the fuller one below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="chop-after-regex" as="xs:string"/>
        <xsl:copy-of
            select="tan:chop-string($input, $chop-after-regex, $do-not-chop-parenthetical-clauses)"
        />
    </xsl:function>
    <xsl:function name="tan:chop-string" as="xs:string*">
        <!-- Input: any string, a regular expression, a boolean -->
        <!-- Output: the input string cut into a sequence of strings using the regular expression as the cut marker -->
        <!-- If the last boolean is true, then nested clauses (parentheses, direct quotations, etc.) will be preserved. -->
        <!-- This function differs from the 1-parameter version in that it is used to chop the string not into individual characters but into words, clauses, sentences, etc. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="chop-after-regex" as="xs:string"/>
        <xsl:param name="preserve-nested-clauses" as="xs:boolean"/>
        <xsl:if test="string-length($input) gt 0">
            <xsl:variable name="input-analyzed" as="element()*">
                <xsl:analyze-string select="$input" regex="{$chop-after-regex}">
                    <xsl:matching-substring>
                        <br>
                            <xsl:value-of select="."/>
                        </br>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <nbr>
                            <xsl:value-of select="."/>
                        </nbr>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$preserve-nested-clauses">
                    <xsl:variable name="input-checked"
                        select="tan:nested-phrase-loop($input-analyzed, ())" as="element()*"/>
                    <xsl:for-each-group select="$input-checked"
                        group-ending-with="tan:br[not(tan:group-data/tan:type)]">
                        <xsl:value-of
                            select="
                                string-join(for $i in current-group()
                                return
                                    $i/tan:val, '')"
                        />
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each-group select="$input-analyzed" group-ending-with="tan:br">
                        <xsl:value-of select="string-join(current-group(), '')"/>
                    </xsl:for-each-group>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>

    <xsl:variable name="nested-phrase-markers" as="element()">
        <grouping-data>
            <pair>
                <open>[</open>
                <close>]</close>
            </pair>
            <pair>
                <open>(</open>
                <close>)</close>
            </pair>
            <pair>
                <open>&lt;</open>
                <close>></close>
            </pair>
            <pair>
                <open>"</open>
                <close>"</close>
            </pair>
            <pair>
                <open>»</open>
                <close>«</close>
            </pair>
            <pair>
                <open>{</open>
                <close>}</close>
            </pair>
            <pair>
                <open>‘</open>
                <open>‚</open>
                <close>’</close>
            </pair>
            <pair>
                <open>“</open>
                <open>„</open>
                <close>”</close>
            </pair>
            <pair>
                <open>‹</open>
                <close>›</close>
            </pair>
            <pair>
                <open>《</open>
                <close>》</close>
            </pair>
            <pair>
                <open>『</open>
                <close>』</close>
            </pair>
            <pair>
                <open>﹃</open>
                <close>﹄</close>
            </pair>
            <pair>
                <open>〈</open>
                <close>〉</close>
            </pair>
            <pair>
                <open>「</open>
                <close>」</close>
            </pair>
            <pair>
                <open>﹁</open>
                <close>﹂</close>
            </pair>
        </grouping-data>
    </xsl:variable>
    <xsl:variable name="nested-phrase-marker-regex"
        select="concat('[', tan:escape(string-join($nested-phrase-markers/tan:pair/*/text(), '')), ']')"/>
    <xsl:variable name="nested-phrase-close-marker-regex"
        select="concat('[', tan:escape(string-join($nested-phrase-markers/tan:pair/tan:close/text(), '')), ']')"/>

    <xsl:function name="tan:nested-phrase-loop" as="element()*">
        <!-- Input: a series of elements with text content; an element indicating what nesting exists so far -->
        <!-- Output: each input element with the text value put into <val> and a  -->
        <xsl:param name="elements-to-process" as="element()*"/>
        <xsl:param name="current-nesting-data" as="element()?"/>
        <xsl:choose>
            <xsl:when test="count($elements-to-process) lt 1"/>
            <xsl:otherwise>
                <xsl:variable name="this-element" select="$elements-to-process[1]"/>
                <xsl:variable name="this-element-analyzed" as="element()*">
                    <xsl:analyze-string select="$this-element" regex="{$nested-phrase-marker-regex}">
                        <xsl:matching-substring>
                            <xsl:variable name="this-match" select="."/>
                            <xsl:variable name="closing-group-opener"
                                select="$nested-phrase-markers/tan:pair[tan:close = $this-match]/tan:open[1]"/>
                            <type>
                                <xsl:attribute name="level"
                                    select="
                                        if (exists($closing-group-opener)) then
                                            -1
                                        else
                                            1"/>
                                <xsl:if test="$this-match = $closing-group-opener">
                                    <xsl:attribute name="toggle"/>
                                </xsl:if>
                                <xsl:value-of select="($closing-group-opener, $this-match)[1]"/>
                            </type>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:variable name="new-group-data" as="element()">
                    <group-data>
                        <xsl:for-each-group select="$this-element-analyzed, $current-nesting-data/*"
                            group-by=".">
                            <xsl:variable name="this-level" as="xs:integer">
                                <xsl:choose>
                                    <xsl:when test="exists(current-group()/@toggle)">
                                        <xsl:copy-of select="count(current-group()) mod 2"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:copy-of
                                            select="
                                                sum(for $i in current-group()
                                                return
                                                    xs:integer($i/@level))"
                                        />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:if test="$this-level gt 0">
                                <type level="{$this-level}">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </type>
                            </xsl:if>
                        </xsl:for-each-group>
                    </group-data>
                </xsl:variable>
                <xsl:for-each select="$this-element">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="$new-group-data"/>
                        <val>
                            <xsl:value-of select="text()"/>
                        </val>
                    </xsl:copy>
                </xsl:for-each>
                <xsl:copy-of
                    select="tan:nested-phrase-loop($elements-to-process[position() gt 1], $new-group-data)"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="tan:tokenize-text" as="element()*">
        <!-- one-parameter version of the function below -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:copy-of select="tan:tokenize-text($text, $token-definition-default, true())"/>
    </xsl:function>
    <xsl:function name="tan:tokenize-text" as="element()*">
        <!-- three-parameter version of the function below -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:param name="token-definition" as="element(tan:token-definition)?"/>
        <xsl:param name="count-toks" as="xs:boolean?"/>
        <xsl:copy-of select="tan:tokenize-text($text, $token-definition, $count-toks, false(), false())"/>
    </xsl:function>
    <xsl:function name="tan:tokenize-text" as="element()*">
        <!-- Input: any number of strings; a <token-definition>; a boolean indicating whether tokens should be counted and labeled. -->
        <!-- Output: a <result> for each string, tokenized into <tok> and <non-tok>, respectively. If the counting option is turned on, the <result> contains @tok-count and @non-tok-count, and each <tok> and <non-tok> have an @n indicating which <tok> group it belongs to. -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:param name="token-definition" as="element(tan:token-definition)?"/>
        <xsl:param name="count-toks" as="xs:boolean?"/>
        <xsl:param name="add-attr-q" as="xs:boolean?"/>
        <xsl:param name="add-attr-pos" as="xs:boolean?"/>
        
        <xsl:variable name="this-tok-def"
            select="
                if (exists($token-definition)) then
                    $token-definition
                else
                    $token-definition-default"/>
        <xsl:variable name="pattern" select="$this-tok-def/@pattern"/>
        <xsl:variable name="this-regex-is-valid" select="tan:regex-is-valid($pattern)"/>
        <xsl:variable name="pattern-adjusted"
            select="
                if ((string-length($pattern) gt 0) and ($this-regex-is-valid = true())) then
                    $pattern
                else
                    '.+'"/>
        <xsl:variable name="flags" select="$this-tok-def/@flags"/>
        <xsl:if test="$this-regex-is-valid = false()">
            <xsl:message select="'Regex ' || $pattern || ' is not a valid regular expression.'"/>
        </xsl:if>
        <xsl:variable name="pass-1" as="element()*">
            <xsl:for-each select="$text">
                <results regex="{$pattern}" flags="{$flags}">
                    <xsl:analyze-string select="." regex="{$pattern-adjusted}">
                        <xsl:matching-substring>
                            <tok>
                                <xsl:value-of select="."/>
                            </tok>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <non-tok>
                                <xsl:value-of select="."/>
                            </non-tok>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </results>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="pass-2" as="element()*">
            <xsl:choose>
                <xsl:when test="$add-attr-pos = true()">
                    <xsl:apply-templates select="$pass-1" mode="add-tok-pos"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$pass-1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:tokenize-text()'"/>
            <xsl:message select="'this token definition pattern: ', string($pattern)"/>
            <xsl:message select="'pattern codepoints: ', string-to-codepoints($pattern)"/>
            <xsl:message select="'this token definition pattern adjusted: ', string($pattern-adjusted)"/>
            <xsl:message select="'add @q?', $add-attr-q"/>
            <xsl:message select="'add @pos?', $add-attr-pos"/>
            <xsl:message select="'pass 2: ', $pass-2"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="not(exists($pattern)) or string-length($pattern) lt 1">
                <xsl:message select="'Tokenization definition has no pattern.'"/>
                <xsl:sequence select="$pass-2"/>
            </xsl:when>
            <xsl:when test="$count-toks = true()">
                <xsl:for-each select="$pass-2">
                    <results tok-count="{count(tan:tok)}" non-tok-count="{count(tan:non-tok)}">
                        <xsl:for-each-group select="*" group-starting-with="tan:tok">
                            <xsl:variable name="pos" select="position()"/>
                            <xsl:for-each select="current-group()">
                                <!-- NB, <non-tok>s will attract the @pos of their master <tok> @pos, making it easy to group tokens with the non-tokens that follow. -->
                                <xsl:copy>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:attribute name="n" select="$pos"/>
                                    <xsl:if test="$add-attr-q = true()">
                                        <xsl:attribute name="q" select="generate-id(.)"/>
                                    </xsl:if>
                                    <xsl:value-of select="."/>
                                </xsl:copy>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </results>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$add-attr-q = true()">
                <xsl:apply-templates select="$pass-2" mode="first-stamp-shallow-copy">
                    <xsl:with-param name="add-q-ids" select="true()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$pass-2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="tan:tok" mode="add-tok-pos">
        <xsl:variable name="this-val" select="text()"/>
        <xsl:variable name="prev-toks" select="preceding-sibling::tan:tok[. = $this-val]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="pos" select="count($prev-toks) + 1"/>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="tan:unique-char" as="xs:string?">
        <!-- Input: any sequence of strings -->
        <!-- Output: a single character that is not to be found in those strings -->
        <!-- This function, written to support tan:collate-sequences(), provides unique way to join any sequence strings in such a way that it can later be tokenized. -->
        <xsl:param name="context-strings" as="xs:string*"/>
        <xsl:variable name="codepoints-used" as="xs:integer*"
            select="
                for $i in ($context-strings)
                return
                    string-to-codepoints($i)"/>
        <xsl:copy-of select="codepoints-to-string(max($codepoints-used) + 1)"/>
    </xsl:function>
    
    <xsl:function name="tan:ellipses" as="xs:string*">
        <!-- Input: any sequence of strings; an integer -->
        <!-- Output: the sequence of strings, but with any substring beyond the requested length replaced by ellipses -->
        <xsl:param name="strings-to-truncate" as="xs:string*"/>
        <xsl:param name="string-length-to-retain" as="xs:integer"/>
        <xsl:for-each select="$strings-to-truncate">
            <xsl:choose>
                <xsl:when test="string-length(.) lt $string-length-to-retain">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring(., 1, $string-length-to-retain) || '...'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>




    <!-- A sequence of doubles, going from 1.0 to 0.00...1 that specify what portion of the length of the text should 
        be checked at each outer loop pass -->
    <xsl:param name="vertical-stops"
        select="
            for $i in (0 to 15)
            return
                math:pow(2, (-0.5 * $i))"/>
    <xsl:function name="tan:vertical-stops" as="xs:double*">
        <!-- Input: a string -->
        <!-- Output: percentages of the string that should be followed in tan:diff-outer-loop() -->
        <xsl:param name="short-string" as="xs:string?"/>
        <xsl:variable name="short-string-length" select="string-length($short-string)"/>
        <xsl:choose>
            <xsl:when test="$short-string-length = 0"/>
            <xsl:when test="$short-string-length lt 7">
                <xsl:copy-of
                    select="
                        for $i in (1 to $short-string-length)
                        return
                            (1 div $i)"
                />
            </xsl:when>
            <xsl:when test="$short-string-length le 20">
                <xsl:copy-of select="(1, 0.8, 0.6, 0.4, 0.3, 0.2, 0.1, 0.005)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$vertical-stops"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Parameters for handling strings in diff -->

    <!-- At what point is the shortest string so long that it would be better to do some pre-processing? -->
    <xsl:param name="long-string-length-min" as="xs:integer" select="1000"/>
    <!-- What is the maximum string length that should be allowed in a single diff operation? Anything larger than this will be pushed to tan:giant-diff() and cut into segments -->
    <xsl:param name="max-small-string-length-allowed-for-diff" as="xs:integer" select="1000000"/>
    
    <!-- What is the maximum size for a segment in a giant diff? For speed use something like 320000; for accuracy, try 1000000 -->
    <xsl:param name="maximum-size-of-giant-string-segments" as="xs:integer" select="1000000"/>
    <!-- What is the minimum number of segments into which a giant string should be chopped when processing a tan:giant-diff()? -->
    <xsl:param name="minimum-number-of-giant-string-segments" as="xs:integer" select="2"/>


    <xsl:function name="tan:diff" as="element()">
        <!-- 2-param version of fuller one below -->
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:sequence select="tan:diff($string-a, $string-b, true())"/>
    </xsl:function>
    <xsl:function name="tan:diff" as="element()">
        <!-- 3-param version of fuller one below -->
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:param name="snap-to-word" as="xs:boolean"/>
        <xsl:sequence select="tan:diff($string-a, $string-b, $snap-to-word, true())"/>
    </xsl:function>
    <xsl:function name="tan:diff" as="element()">
        <!-- This function prepares strings for 5-ary tan:diff(), primarily by tending to input strings
        that are large or really large (giant). Large pairs of strings are parsed to find common characters
        that might be used to find pairwise congruence of large segments. Giant pairs of strings are passed 
        to tan:giant-diff(). -->
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:param name="snap-to-word" as="xs:boolean"/>
        <xsl:param name="preprocess-long-strings" as="xs:boolean"/>
        <xsl:variable name="str-a-len" select="string-length($string-a)"/>
        <xsl:variable name="str-b-len" select="string-length($string-b)"/>
        <xsl:variable name="smallest-string-length" select="min(($str-a-len, $str-b-len))"/>
        <xsl:variable name="diff-must-be-chained"
            select="$smallest-string-length gt $max-small-string-length-allowed-for-diff"
        />
        <xsl:choose>
            <xsl:when test="$diff-must-be-chained">
                <xsl:variable name="str-a-seg-len" as="xs:decimal"
                    select="ceiling($str-a-len div $minimum-number-of-giant-string-segments)"
                />
                <xsl:variable name="str-b-seg-len" as="xs:decimal"
                    select="ceiling($str-b-len div $minimum-number-of-giant-string-segments)"
                />
                <xsl:variable name="max-str-seg-len" select="max(($str-a-seg-len, $str-b-seg-len))"/>
                <xsl:variable name="adjustment-ratio"
                    select="
                        if ($max-str-seg-len gt $maximum-size-of-giant-string-segments) then
                            ($maximum-size-of-giant-string-segments div $max-str-seg-len)
                        else
                            1"
                />
                
                <xsl:variable name="diagnostics-on" select="true()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'Diagnostics on, tan:diff(), giant string branch'"/>
                    <xsl:message select="'String a (length ' || string($str-a-len) || '): ' || tan:ellipses($string-a, 40)"/>
                    <xsl:message select="'String b (length ' || string($str-b-len) || '): ' || tan:ellipses($string-b, 40)"/>
                    <xsl:message select="'String a segment length:', $str-a-seg-len"/>
                    <xsl:message select="'String b segment length:', $str-b-seg-len"/>
                    <xsl:message select="'Adjustment ratio:', $adjustment-ratio"/>
                </xsl:if>
                
                <xsl:copy-of select="tan:giant-diff($string-a, $string-b, $snap-to-word, xs:integer($str-a-seg-len * $adjustment-ratio), xs:integer($str-b-seg-len * $adjustment-ratio))"/>
            </xsl:when>
            <xsl:when
                test="($preprocess-long-strings = false()) or 
                (($str-a-len lt $long-string-length-min) or ($str-b-len lt $long-string-length-min))">
                <xsl:sequence select="tan:diff($string-a, $string-b, $snap-to-word, (), 0)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="strings-char-inv" as="element()*">
                    <xsl:for-each select="$string-a, $string-b">
                        <text>
                            <xsl:for-each-group select="string-to-codepoints(.)" group-by=".">
                                <xsl:sort select="count(current-group())"/>
                                <xsl:if test="current-grouping-key() ge 32">
                                    <tok count="{count(current-group())}"
                                        cp="{current-grouping-key()}">
                                        <xsl:value-of
                                            select="codepoints-to-string(current-grouping-key())"/>
                                    </tok>
                                </xsl:if>
                            </xsl:for-each-group>
                        </text>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="strings-char-inv-grouped" as="element()*">
                    <xsl:for-each-group select="$strings-char-inv/*" group-by=".">
                        <xsl:sort select="count(current-group())"/>
                        <xsl:choose>
                            <xsl:when test="count(current-group()) eq 1">
                                <unique><xsl:copy-of select="current-group()"/></unique>
                            </xsl:when>
                            <xsl:otherwise>
                                <shared><xsl:copy-of select="current-group()[1]"/></shared>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group> 
                </xsl:variable>
                <xsl:variable name="unique-strings-sorted" as="xs:string*">
                    <!-- We must make sure to put hyphens at the end of a character class -->
                    <xsl:for-each select="$strings-char-inv-grouped/self::tan:unique/tan:tok">
                        <xsl:sort
                            select="
                                if (. = '-') then
                                    9
                                else
                                    1"
                        />
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="strings-for-tokenizing" as="xs:string*"
                    select="string-join($unique-strings-sorted, '')[string-length(.) gt 0], $strings-char-inv-grouped/self::tan:shared/tan:tok/text()"
                />
                <xsl:sequence
                    select="tan:diff($string-a, $string-b, $snap-to-word, $strings-for-tokenizing, 0)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="tan:diff" as="element()">
        <!-- Input: any two strings; boolean indicating whether results should snap to nearest word; boolean 
            indicating whether long strings should be pre-processed -->
        <!-- Output: an element with <a>, <b>, and <common> children showing where strings a and b match 
            and depart -->
        <!-- This function was written to assist the validation of <redivision>s quickly find differences 
            between any two strings. The function has been tested on pairs of strings up to combined lengths of 
            9M characters. At that scale, the only way to efficiently process the diffs is by chaining smaller 
            diffs, which are still large, optimally about 350K in length. -->
        
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:param name="snap-to-word" as="xs:boolean"/>
        <xsl:param name="characters-to-tokenize-on" as="xs:string*"/>
        <xsl:param name="loop-counter" as="xs:integer"/>
        
        <xsl:variable name="str-a-len" select="string-length($string-a)"/>
        <xsl:variable name="str-b-len" select="string-length($string-b)"/>
        <xsl:variable name="strings-prepped" as="element()+">
            <xsl:choose>
                <xsl:when test="$str-a-len lt $str-b-len">
                    <a><xsl:value-of select="$string-a"/></a>
                    <b><xsl:value-of select="$string-b"/></b>
                </xsl:when>
                <xsl:otherwise>
                    <b><xsl:value-of select="$string-b"/></b>
                    <a><xsl:value-of select="$string-a"/></a>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="some-string-is-zero-length"
            select="($str-a-len lt 1) or ($str-b-len lt 1)"/>
        <xsl:variable name="does-not-need-preprocessing" as="xs:boolean"
            select="
                not(exists($characters-to-tokenize-on)) or
                (min(($str-a-len, $str-b-len)) lt $long-string-length-min)"
        />

        <xsl:variable name="next-tokenization-string" select="$characters-to-tokenize-on[1]"/>
        <xsl:variable name="tokenize-on" as="xs:string"
            select="concat('[', tan:escape($next-tokenization-string), ']')"/>
        
        <xsl:variable name="strings-diffed" as="element()*">
            <xsl:choose>
                <xsl:when test="$loop-counter ge $loop-tolerance">
                    <xsl:message
                        select="concat('Diff function cannot be repeated more than ', xs:string($loop-tolerance), ' times')"/>
                    <xsl:sequence select="$strings-prepped/self::a, $strings-prepped/self::b"/>
                </xsl:when>
                <xsl:when test="$some-string-is-zero-length">
                    <xsl:sequence select="$strings-prepped[text()]"/>
                </xsl:when>
                <xsl:when test="$does-not-need-preprocessing">
                    <xsl:variable name="pass-1" as="element()*">
                        <xsl:copy-of
                            select="tan:diff-outer-loop($strings-prepped[1], $strings-prepped[2], true(), false(), $vertical-stops, 0)"
                        />
                    </xsl:variable>
                    
                    <xsl:variable name="diagnostics-on" select="false()"/>
                    <xsl:if test="$diagnostics-on">
                        <xsl:message select="'diagnostics on, tan:diff(), branch where preprocessing is not needed.'"/>
                        <xsl:message select="concat('String a length: ', string($str-a-len), ' (', tan:ellipses($string-a, 20), '); string b length: ', string($str-b-len), ' (', tan:ellipses($string-b, 20), ')')"/>
                        <xsl:message select="'Pass 1:', $pass-1"/>
                    </xsl:if>
                    
                    <xsl:for-each-group select="$pass-1" group-adjacent="name() = 'common'">
                        <xsl:choose>
                            <xsl:when test="current-grouping-key()">
                                <xsl:copy-of select="current-group()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each-group select="current-group()" group-by="name()">
                                    <xsl:sort select="current-grouping-key()"/>
                                    <xsl:element name="{current-grouping-key()}">
                                        <xsl:value-of select="string-join(current-group(), '')"/>
                                    </xsl:element>
                                </xsl:for-each-group>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Pre-process long strings by first analyzing co-occurrence of unique words -->
                    <!-- Build a variable with two elements, one for each input string, containing <tok> and <non-tok> -->
                    
                    <xsl:if test="$tokenize-on eq '[]'">
                        <xsl:message select="'tokenization patterns ', $characters-to-tokenize-on"/>
                        <xsl:message terminate="yes"
                            select="'faulty next tok string cp ', string-to-codepoints($next-tokenization-string)"
                        />
                        
                    </xsl:if>

                    
                    <xsl:variable name="input-a-analyzed" as="xs:string*">
                        <xsl:analyze-string select="$string-a" regex="{$tokenize-on}">
                            <xsl:matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="input-b-analyzed" as="xs:string*">
                        <xsl:analyze-string select="$string-b" regex="{$tokenize-on}">
                            <xsl:matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    
                    <!-- Reduce each of the two elements to a set of tokens unique to that string -->
                    
                    <xsl:variable name="input-a-unique-words" as="xs:string*">
                        <xsl:for-each-group select="$input-a-analyzed" group-by=".">
                            <xsl:if test="count(current-group()) = 1">
                                <xsl:sequence select="current-group()"/>
                            </xsl:if>
                        </xsl:for-each-group> 
                    </xsl:variable>
                    <xsl:variable name="input-b-unique-words" as="xs:string*">
                        <xsl:for-each-group select="$input-b-analyzed" group-by=".">
                            <xsl:if test="count(current-group()) = 1">
                                <xsl:sequence select="current-group()"/>
                            </xsl:if>
                        </xsl:for-each-group> 
                    </xsl:variable>
                    
                    
                    <xsl:variable name="input-core-sequence"
                        select="
                            tan:collate-pair-of-sequences($input-a-unique-words, $input-b-unique-words)"
                    />
                    
                    
                    <xsl:variable name="input-core-shared-unique-words-in-same-order"
                        select="$input-core-sequence[exists(@p1) and exists(@p2)][not(. eq $next-tokenization-string)]"/>
                    
                    <xsl:variable name="this-unique-sequence-count"
                        select="count($input-core-shared-unique-words-in-same-order)"/>
                    <xsl:variable name="input-analyzed-2" as="element()*">
                        <a>
                            <xsl:for-each-group select="$input-a-analyzed"
                                group-ending-with=".[. = $input-core-shared-unique-words-in-same-order]">
                                <xsl:variable name="last-is-not-common"
                                    select="position() gt $this-unique-sequence-count"/>
                                <group n="{position()}" input="1">
                                    <xsl:choose>
                                        <xsl:when test="$last-is-not-common">
                                            <distinct input="1">
                                                <xsl:value-of
                                                  select="string-join(current-group(), '')"/>
                                            </distinct>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <distinct input="1">
                                                <xsl:value-of
                                                  select="string-join(current-group()[not(position() eq last())], '')"
                                                />
                                            </distinct>
                                            <common>
                                                <xsl:value-of select="current-group()[last()]"/>
                                            </common>
                                        </xsl:otherwise>

                                    </xsl:choose>
                                </group>
                            </xsl:for-each-group>
                        </a>
                        <b>
                            <xsl:for-each-group select="$input-b-analyzed"
                                group-ending-with=".[. = $input-core-shared-unique-words-in-same-order]">
                                <xsl:variable name="last-is-not-common"
                                    select="position() gt $this-unique-sequence-count"/>
                                <group n="{position()}" input="2">
                                    <xsl:choose>
                                        <xsl:when test="$last-is-not-common">
                                            <distinct input="2">
                                                <xsl:value-of
                                                  select="string-join(current-group(), '')"/>
                                            </distinct>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <distinct input="1">
                                                <xsl:value-of
                                                    select="string-join(current-group()[not(position() eq last())], '')"
                                                />
                                            </distinct>
                                            <common>
                                                <xsl:value-of select="current-group()[last()]"/>
                                            </common>
                                        </xsl:otherwise>

                                    </xsl:choose>
                                </group>
                            </xsl:for-each-group>
                        </b>

                        <!--<xsl:for-each select="$input-analyzed">
                            <xsl:variable name="this-pos" select="position()"/>
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:for-each-group select="*"
                                    group-ending-with="self::*[. = $input-core-shared-unique-words-in-same-order]">
                                    <xsl:variable name="last-is-not-common" select="position() gt $this-unique-sequence-count"/>
                                    <group n="{position()}" input="{$this-pos}">
                                        <xsl:choose>
                                            <xsl:when test="$last-is-not-common">
                                                <distinct input="{$this-pos}">
                                                  <xsl:value-of
                                                  select="string-join(current-group(), '')"/>
                                                  </distinct>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:variable name="this-common-node" select="current-group()[last()]"/>
                                                <distinct input="{$this-pos}">
                                                    <xsl:value-of
                                                        select="string-join(current-group() except $this-common-node, '')"/>
                                                </distinct>
                                                <common>
                                                    <xsl:value-of select="$this-common-node"/>
                                                </common>
                                            </xsl:otherwise>
                                            
                                        </xsl:choose>
                                    </group>
                                </xsl:for-each-group>
                            </xsl:copy>
                        </xsl:for-each>-->
                    </xsl:variable>
                    
                    <!-- If something goes awry, it can be very helpful to trace a particular phrase as it gets handled. By entering
                    something in the following variable, the message on $input-analyzed will signify via an asterisk into which fork the  
                    phrase is being placed. -->
                    <xsl:variable name="diagnostics-regex" as="xs:string" select="'Enter a regular expression to trace in strings a and b'"/>
                    <xsl:variable name="diagnostics-on" select="false()"/>
                    <xsl:if test="$diagnostics-on">
                        <xsl:message select="'diagnostics on, tan:diff(), branch to preprocess long strings.'"/>
                        <xsl:message select="'String a (length ' || string($str-a-len) || '): ' || tan:ellipses($string-a, 40)"/>
                        <xsl:message select="'String b (length ' || string($str-b-len) || '): ' || tan:ellipses($string-b, 40)"/>
                        <xsl:message select="'next tokenization string (', string-to-codepoints($next-tokenization-string), '): ', $next-tokenization-string"/>
                        <xsl:message select="'tokenization pattern: ', $tokenize-on"/>
                        <xsl:message select="'all tokenization strings: ', string-join($characters-to-tokenize-on, ' ')"/>
                        <xsl:message select="'all tokenization string codepoints: ', string-to-codepoints(string-join($characters-to-tokenize-on, ''))"/>
                        <xsl:message select="'input A analyzed/tokenized (', count($input-a-analyzed), ') first three:', tan:ellipses($input-a-analyzed, 10)"/>
                        <xsl:message select="'input B analyzed/tokenized (', count($input-b-analyzed), ') first three:', tan:ellipses($input-b-analyzed, 10)"/>
                        <xsl:message select="'input A unique words (', count($input-a-unique-words), '): ', tan:ellipses($input-a-unique-words, 10)"/>
                        <xsl:message select="'input B unique words (', count($input-b-unique-words), '): ', tan:ellipses($input-b-unique-words, 10)"/>
                        <xsl:message select="'input core sequence (', count($input-core-sequence), '): ', serialize(tan:trim-long-text($input-core-sequence, 10))"/>
                        <xsl:message
                            select="
                                'Input core shared unique words in same order (', count($input-core-shared-unique-words-in-same-order), '): ',
                                string-join(for $i in $input-core-shared-unique-words-in-same-order
                                return
                                    (tan:ellipses($i, 10), concat('(length ', string(string-length($i)), ') ')), ' ')"
                        />
                        <xsl:message
                            select="
                                'Input analyzed (lengths',
                                for $i in $input-analyzed-2
                                return
                                    concat(' ', name($i), ': ', string-join(for $j in $i//text(),
                                        $k in matches($j, $diagnostics-regex)
                                    return
                                        concat(string(string-length($j)), (if ($k) then
                                            '*'
                                        else
                                            ())), ', ')), '): ', serialize(tan:trim-long-text($input-analyzed-2, 10))"
                        />
                    </xsl:if>
                    
                    <xsl:for-each-group select="$input-analyzed-2/tan:group" group-by="@n">
                        <xsl:copy-of select="tan:diff(current-group()[@input='1']/tan:distinct, current-group()[@input='2']/tan:distinct,
                            $snap-to-word, $characters-to-tokenize-on[position() gt 1], $loop-counter + 1)/*"/>
                        <xsl:copy-of select="current-group()[1]/tan:common"/>
                    </xsl:for-each-group> 
                    
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="results-cleaned" as="element()">
            <diff>
                <xsl:for-each-group select="$strings-diffed" group-adjacent="name()">
                    <xsl:element name="{current-grouping-key()}">
                        <xsl:value-of select="string-join(current-group(), '')"/>
                    </xsl:element>
                </xsl:for-each-group>
            </diff>
        </xsl:variable>
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:diff()'"/>
            <xsl:message select="'loop number: ', string($loop-counter)"/>
            <xsl:message
                select="'string a (length ', string-length($string-a), '): ', tan:trim-long-text($string-a, 40)"/>
            <xsl:message
                select="'string b (length ', string-length($string-b), '): ', tan:trim-long-text($string-b, 40)"/>
            <xsl:message select="'some string is zero length?: ', $some-string-is-zero-length"/>
            <xsl:message select="'needs preprocessing?: ', not($does-not-need-preprocessing)"/>
            <xsl:message select="'snap to word: ', string($snap-to-word)"/>
            <xsl:message select="'characters to tokenize on: ', string-join($characters-to-tokenize-on, ' ')"/>
            <xsl:message select="'strings diffed: ', $strings-diffed"/>
            <xsl:message select="'results cleaned', $results-cleaned"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$snap-to-word">
                <xsl:variable name="snap1" as="element()">
                    <xsl:apply-templates select="$results-cleaned" mode="snap-to-word-pass-1"/>
                </xsl:variable>
                <xsl:variable name="snap2" as="element()">
                    <!-- It happens that sometimes matching words get restored in this process, either at the beginning or the end of an <a> or <b>; this step moves those common words back into the common pool -->
                    <snap2>
                        <xsl:for-each-group select="$snap1/*" group-starting-with="tan:common">
                            <xsl:copy-of select="current-group()/self::tan:common"/>
                            <xsl:variable name="text-a"
                                select="string-join(current-group()/(self::tan:a, self::tan:a-or-b), '')"/>
                            <xsl:variable name="text-b"
                                select="string-join(current-group()/(self::tan:b, self::tan:a-or-b), '')"/>
                            <xsl:variable name="a-toks" as="xs:string*">
                                <xsl:analyze-string select="$text-a" regex="\s+">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:variable>
                            <xsl:variable name="b-toks" as="xs:string*">
                                <xsl:analyze-string select="$text-b" regex="\s+">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:variable>
                            <xsl:variable name="a-tok-qty" select="count($a-toks)"/>
                            <xsl:variable name="b-tok-qty" select="count($b-toks)"/>
                            <xsl:variable name="non-matches-from-start" as="xs:integer*">
                                <!-- We are looking for first word where there isn't a match -->
                                <xsl:for-each select="$a-toks">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:if test="not(. = $b-toks[$pos])">
                                        <xsl:value-of select="$pos"/>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:if test="$a-tok-qty lt $b-tok-qty">
                                    <xsl:value-of select="$a-tok-qty + 1"/>
                                </xsl:if>
                            </xsl:variable>
                            <!-- grab those tokens in b starting with the first non match and reverse the order -->
                            <xsl:variable name="b-nonmatches-rev"
                                select="reverse($b-toks[position() ge $non-matches-from-start[1]])"/>
                            <xsl:variable name="a-nonmatches-rev"
                                select="reverse($a-toks[position() ge $non-matches-from-start[1]])"/>
                            <xsl:variable name="non-matches-from-end" as="xs:integer*">
                                <!-- We're looking for the first word from the end where there isn't match -->
                                <xsl:for-each select="$a-nonmatches-rev">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:if test="not(. = $b-nonmatches-rev[$pos])">
                                        <xsl:value-of select="$pos"/>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:if test="count($a-nonmatches-rev) lt count($b-nonmatches-rev)">
                                    <xsl:value-of select="count($a-nonmatches-rev) + 1"/>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:variable name="a-analyzed" as="element()*">
                                <xsl:for-each select="$a-toks">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:variable name="rev-pos" select="$a-tok-qty - $pos"/>
                                    <xsl:choose>
                                        <xsl:when test="$pos lt $non-matches-from-start[1]">
                                            <common-head>
                                                <xsl:value-of select="."/>
                                            </common-head>
                                        </xsl:when>
                                        <xsl:when test="$rev-pos + 1 lt $non-matches-from-end[1]">
                                            <common-tail>
                                                <xsl:value-of select="."/>
                                            </common-tail>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <a>
                                                <xsl:value-of select="."/>
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:variable name="b-analyzed" as="element()*">
                                <xsl:for-each
                                    select="
                                        $b-toks[position() ge $non-matches-from-start[1]
                                        and position() le ($b-tok-qty - $non-matches-from-end[1] + 1)]">
                                    <b>
                                        <xsl:value-of select="."/>
                                    </b>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each-group select="($a-analyzed, $b-analyzed)"
                                group-by="name()">
                                <xsl:sort
                                    select="index-of(('common-head', 'a', 'b', 'common-tail'), current-grouping-key())"/>
                                <xsl:variable name="element-name"
                                    select="replace(current-grouping-key(), '-.+', '')"/>
                                <xsl:element name="{$element-name}">
                                    <xsl:value-of select="string-join(current-group(), '')"/>
                                </xsl:element>
                            </xsl:for-each-group>
                        </xsl:for-each-group>
                    </snap2>
                </xsl:variable>
                <!-- diagnostics, results -->
                <!--<xsl:copy-of select="$snap1"/>-->
                <!--<xsl:copy-of select="$strings-prepped"/>-->
                <!--<xsl:copy-of select="$strings-diffed"/>-->
                <!--<xsl:copy-of select="$snap2"/>-->
                <!--<xsl:copy-of select="tan:merge-adjacent-elements($snap2/*)"/>-->
                <diff>
                    <xsl:for-each-group select="$snap2/*" group-adjacent="name()">
                        <xsl:element name="{current-grouping-key()}">
                            <xsl:value-of select="string-join(current-group(), '')"/>
                        </xsl:element>
                    </xsl:for-each-group>
                </diff>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$results-cleaned"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="tan:common" mode="snap-to-word-pass-1">
        <xsl:variable name="preceding-diff"
            select="preceding-sibling::*[1][self::tan:a or self::tan:b]"/>
        <xsl:variable name="following-diff"
            select="following-sibling::*[1][self::tan:a or self::tan:b]"/>
        <xsl:choose>
            <xsl:when test="exists($preceding-diff) or exists($following-diff)">
                <xsl:variable name="regex-1"
                    select="
                        if (exists($preceding-diff)) then
                            '^\w+'
                        else
                            ()"/>
                <xsl:variable name="regex-2"
                    select="
                        if (exists($following-diff)) then
                            '\w+$'
                        else
                            ()"/>
                <xsl:variable name="content-analyzed" as="element()">
                    <content>
                        <xsl:analyze-string select="text()"
                            regex="{string-join(($regex-1, $regex-2),'|')}">
                            <xsl:matching-substring>
                                <a-or-b>
                                    <xsl:value-of select="."/>
                                </a-or-b>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <common>
                                    <xsl:value-of select="."/>
                                </common>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </content>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="matches($content-analyzed/tan:common, '\S')">
                        <xsl:copy-of select="$content-analyzed/*"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <a-or-b>
                            <xsl:value-of select="."/>
                        </a-or-b>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>




    <xsl:function name="tan:diff-outer-loop">
        <xsl:param name="short-string" as="element()?"/>
        <xsl:param name="long-string" as="element()?"/>
        <xsl:param name="start-at-beginning" as="xs:boolean"/>
        <xsl:param name="check-vertically-before-horizontally" as="xs:boolean"/>
        <xsl:param name="vertical-stops-to-process" as="xs:double*"/>
        <xsl:param name="loop-counter" as="xs:integer"/>
        
        <xsl:variable name="short-size" select="string-length($short-string)"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:diff-outer-loop()'"/>
            <xsl:message select="'loop number ', $loop-counter"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="string-length($long-string) lt 1"/>
            <xsl:when test="$short-size lt 1">
                <xsl:if test="$diagnostics-on">
                    <xsl:message>short doesn't exist</xsl:message>
                </xsl:if>
                <xsl:for-each select="$long-string">
                    <xsl:copy>
                        <xsl:attribute name="outer-loop" select="$loop-counter"/>
                        <xsl:value-of select="."/>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$short-string = $long-string">
                <common outer-loop="{$loop-counter}">
                    <xsl:value-of select="$short-string"/>
                </common>
            </xsl:when><!-- matches($long-string, tan:escape($short-string)) -->
            <xsl:when test="matches($long-string, $short-string, 'q')">
                <xsl:variable name="this-analysis" as="element()">
                    <analysis><!-- {tan:escape($short-string/text())} -->
                        <xsl:analyze-string select="$long-string/text()"
                            regex="{$short-string/text()}" flags="q">
                            <xsl:matching-substring>
                                <common outer-loop="{$loop-counter}">
                                    <xsl:value-of select="."/>
                                </common>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:element name="{name($long-string)}">
                                    <xsl:value-of select="."/>
                                </xsl:element>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </analysis>
                </xsl:variable>
                <xsl:copy-of select="$this-analysis/tan:common[1]/preceding-sibling::*"/>
                <xsl:copy-of select="$this-analysis/tan:common[1]"/>
                <xsl:variable name="this-analysis-tail"
                    select="$this-analysis/tan:common[1]/following-sibling::*"/>
                <xsl:if test="exists($this-analysis-tail)">
                    <xsl:element name="{name($long-string)}">
                        <xsl:value-of select="string-join($this-analysis-tail, '')"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$loop-counter ge $loop-tolerance">
                <xsl:message
                    select="concat('Outer loop cannot go beyond ', xs:string($loop-tolerance), ' passes')"/>
                <xsl:copy-of select="$short-string, $long-string"/>
            </xsl:when>
            <xsl:when test="count($vertical-stops-to-process) lt 0">
                <xsl:message>Out of vertical stops</xsl:message>
                <xsl:copy-of select="$short-string"/>
                <xsl:copy-of select="$long-string"/>
            </xsl:when>
            <xsl:when test="$check-vertically-before-horizontally and $start-at-beginning">
                <xsl:variable name="this-common-start" select="tan:common-start-string(($short-string, $long-string))"/>
                <xsl:variable name="this-common-start-length" select="string-length($this-common-start)"/>
                <xsl:choose>
                    <xsl:when test="$this-common-start-length gt 0">
                        <xsl:variable name="new-short" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($short-string, $this-common-start-length + 1)"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="new-long" as="element()">
                            <xsl:element name="{name($long-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($long-string, $this-common-start-length + 1)"/>
                            </xsl:element>
                        </xsl:variable>
                        
                        <!--<xsl:message select="'common start: ', $this-common-start"/>
                        <xsl:message select="'cs length:', $this-common-start-length"/>
                        <xsl:message select="'new short:', $new-short"/>
                        <xsl:message select="'new long:', $new-long"/>-->
                        
                        <common outer-loop="{$loop-counter}">
                            <xsl:value-of select="$this-common-start"/>
                        </common>
                        <xsl:copy-of select="tan:diff-outer-loop($new-short, $new-long, true(), false(), $vertical-stops-to-process, $loop-counter + 1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="tan:diff-outer-loop($short-string, $long-string, true(), false(), $vertical-stops-to-process, $loop-counter + 1)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$check-vertically-before-horizontally and not($start-at-beginning)">
                <xsl:variable name="this-common-end" select="tan:common-end-string(($short-string, $long-string))"/>
                <xsl:variable name="this-common-end-length" select="string-length($this-common-end)"/>
                <xsl:choose>
                    <xsl:when test="$this-common-end-length gt 0">
                        <xsl:variable name="new-short" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($short-string, 1, (string-length($short-string) - $this-common-end-length))"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="new-long" as="element()">
                            <xsl:element name="{name($long-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($long-string, 1, (string-length($long-string) - $this-common-end-length))"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:copy-of select="tan:diff-outer-loop($new-short, $new-long, true(), false(), $vertical-stops-to-process, $loop-counter + 1)"/>
                        <common outer-loop="{$loop-counter}">
                            <xsl:value-of select="$this-common-end"/>
                        </common>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="tan:diff-outer-loop($short-string, $long-string, true(), false(), $vertical-stops-to-process, $loop-counter + 1)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- Now we can search for parts of the short string within the long string -->
                <xsl:variable name="this-vertical-stop" select="$vertical-stops-to-process[1]"/>
                <xsl:variable name="percent-of-short-to-check"
                    select="min((max(($this-vertical-stop, 0.0000001)), 1.0))"/>
                <xsl:variable name="number-of-horizontal-passes"
                    select="
                        if ($check-vertically-before-horizontally) then
                            1
                        else
                            xs:integer((1 - $percent-of-short-to-check) * 50) + 1"/>
                <xsl:variable name="length-of-short-substring" as="xs:integer"
                    select="xs:integer(ceiling($short-size * $percent-of-short-to-check))"/>
                <xsl:variable name="length-of-play-in-short"
                    select="$short-size - $length-of-short-substring"/>
                <xsl:variable name="horizontal-stagger"
                    select="$length-of-play-in-short div max(($number-of-horizontal-passes - 1, 1))"/>
                <xsl:variable name="starting-pos-of-short-substring" as="xs:integer+"
                    select="
                        distinct-values(for $i in (1 to $number-of-horizontal-passes)
                        return
                            xs:integer(ceiling(($i - 1) * $horizontal-stagger) + 1))"/>
                <xsl:variable name="starting-locs"
                    select="
                        if ($start-at-beginning) then
                            $starting-pos-of-short-substring
                        else
                            for $i in $starting-pos-of-short-substring
                            return
                                $short-size - $length-of-short-substring - $i + 1"/>
                <!-- reverse($starting-pos-of-short-substring) -->
                <xsl:variable name="search-prefix"
                    select="
                        if ($check-vertically-before-horizontally and $start-at-beginning) then
                            '^'
                        else
                            ()"/>
                <xsl:variable name="search-suffix"
                    select="
                        if ($check-vertically-before-horizontally and not($start-at-beginning)) then
                            '$'
                        else
                            ()"/>
                <xsl:variable name="first-result"
                    select="tan:diff-inner-loop($short-string, $long-string, $starting-locs, $length-of-short-substring, $search-prefix, $search-suffix, 0)"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'outer loop number', $loop-counter"/>
                    <xsl:message select="'$short-string:', tan:trim-long-text($short-string, 11)"/>
                    <xsl:message select="'$long-string:', tan:trim-long-text($long-string, 11)"/>
                    <xsl:message select="'$start-at-beginning:', $start-at-beginning"/>
                    <xsl:message
                        select="'$check-vertically-before-horizontally:', $check-vertically-before-horizontally"/>
                    <xsl:message select="'$vertical-stops-to-process:', $vertical-stops-to-process"/>
                    <xsl:message select="'$start-at-beginning:', $start-at-beginning"/>
                    <xsl:message select="'$short-size:', $short-size"/>
                    <xsl:message select="'$this-vertical-stop:', $this-vertical-stop"/>
                    <xsl:message select="'$percent-of-short-to-check:', $percent-of-short-to-check"/>
                    <xsl:message
                        select="'$number-of-horizontal-passes:', $number-of-horizontal-passes"/>
                    <xsl:message select="'$length-of-short-substring:', $length-of-short-substring"/>
                    <xsl:message select="'$length-of-play-in-short:', $length-of-play-in-short"/>
                    <xsl:message select="'$horizontal-stagger:', $horizontal-stagger"/>
                    <xsl:message
                        select="'$starting-pos-of-short-substring:', $starting-pos-of-short-substring"/>
                    <xsl:message select="'$starting-locs:', $starting-locs"/>
                    <xsl:message select="'$search-prefix:', $search-prefix"/>
                    <xsl:message select="'$search-suffix:', $search-suffix"/>
                    <xsl:message select="'$first-result:', serialize($first-result)"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="exists($first-result)">

                        <xsl:variable name="short-search-start"
                            select="xs:integer($first-result/@short-search-start)"/>
                        <xsl:variable name="short-search-length"
                            select="xs:integer($first-result/@short-search-length)"/>
                        <xsl:variable name="long-head" as="element()">
                            <xsl:element name="{name($long-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:copy-of
                                    select="$first-result/tan:common[1]/preceding-sibling::*/text()"
                                />
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="long-tail" as="element()?">
                            <xsl:element name="{name($long-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:copy-of
                                    select="$first-result/tan:common[1]/following-sibling::*/text()"
                                />
                            </xsl:element>
                        </xsl:variable>
                        
                        <!-- There are cases where the common matching string appears more than once, either
                        in the short or the long strings. By using tan:common[1] above we grab the first case in the
                        long string. We should do the same for the short string, so we can't rely exclusively upon the
                        short-search-start or short-search-length. -->
                        <!-- matches($short-string, concat(tan:escape($first-result/tan:common[1]), '$')) -->
                        <xsl:variable name="short-input-should-be-parsed-from-end"
                            select="(not($start-at-beginning) and ends-with($short-string, $first-result/tan:common[1]))"
                        />
                        <xsl:variable name="short-input-parsed" as="element()">
                            <result>
                                <xsl:choose>
                                    <xsl:when test="$short-input-should-be-parsed-from-end">
                                        
                                        <xsl:analyze-string select="$short-string"
                                            regex="{tan:escape($first-result/tan:common[1])}$">
                                            <xsl:matching-substring>
                                                <common>
                                                  <xsl:value-of select="."/>
                                                </common>
                                            </xsl:matching-substring>
                                            <xsl:non-matching-substring>
                                                <xsl:element name="{name($short-string)}">
                                                  <xsl:attribute name="outer-loop"
                                                  select="$loop-counter"/>
                                                  <xsl:value-of select="."/>
                                                </xsl:element>
                                            </xsl:non-matching-substring>
                                        </xsl:analyze-string>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:analyze-string select="$short-string"
                                            regex="{$first-result/tan:common[1]}" flags="q">
                                            <xsl:matching-substring>
                                                <common>
                                                  <xsl:value-of select="."/>
                                                </common>
                                            </xsl:matching-substring>
                                            <xsl:non-matching-substring>
                                                <xsl:element name="{name($short-string)}">
                                                  <xsl:attribute name="outer-loop"
                                                  select="$loop-counter"/>
                                                  <xsl:value-of select="."/>
                                                </xsl:element>
                                            </xsl:non-matching-substring>
                                        </xsl:analyze-string>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </result>
                        </xsl:variable>
                        <xsl:variable name="short-input-common-segment-of-interest"
                            select="
                                if (not($start-at-beginning)) then
                                    $short-input-parsed/tan:common[last()]
                                else
                                    $short-input-parsed/tan:common[1]"
                        />
                        <xsl:variable name="short-head" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:copy-of select="$short-input-common-segment-of-interest/preceding-sibling::*/text()"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="short-tail-elements"
                            select="$short-input-common-segment-of-interest/following-sibling::*"/>
                        <xsl:variable name="short-tail" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:copy-of select="$short-tail-elements/text()"/>
                            </xsl:element>
                        </xsl:variable>
                        
                        <xsl:variable name="head-input" as="element()*">
                            <xsl:for-each select="$long-head, $short-head">
                                <xsl:sort select="string-length(.)"/>
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:variable name="tail-input" as="element()*">
                            <xsl:for-each select="$long-tail, $short-tail">
                                <xsl:sort select="string-length(.)"/>
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:variable>

                        <!-- results -->

                        <!-- need to loop again on head fragments -->
                        <xsl:copy-of
                            select="
                                tan:diff-outer-loop($head-input[1], $head-input[2], false(), true(),
                                tan:vertical-stops($head-input[1]), $loop-counter + 1)"/>

                        <xsl:for-each select="$first-result/tan:common[1]">
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of select="."/>
                            </xsl:copy>
                        </xsl:for-each>

                        <!-- need to loop again on tail fragments -->
                        <xsl:copy-of
                            select="
                                tan:diff-outer-loop($tail-input[1], $tail-input[2], true(), true(),
                                tan:vertical-stops($tail-input[1]), $loop-counter + 1)"/>

                    </xsl:when>
                    <!-- If there are no results on this vertical level... -->
                    <!-- ...try the next vertical level -->
                    <xsl:when test="count($vertical-stops-to-process) gt 1">
                        <xsl:copy-of
                            select="tan:diff-outer-loop($short-string, $long-string, $start-at-beginning, $check-vertically-before-horizontally, $vertical-stops-to-process[position() gt 1], $loop-counter + 1)"
                        />
                    </xsl:when>
                    <!-- If the vertical pass is done, but no horizontal checks have been done, time to restart the process and do horizontal work -->
                    <xsl:when test="$check-vertically-before-horizontally">
                        <xsl:copy-of
                            select="
                                tan:diff-outer-loop($short-string, $long-string, $start-at-beginning, false(), $vertical-stops, $loop-counter + 1)"
                        />
                    </xsl:when>
                    <xsl:when test="$length-of-short-substring le 1">
                        <xsl:if test="$diagnostics-on">
                            <xsl:message select="'substring size below 1'"/>
                        </xsl:if>
                        <xsl:for-each select="$long-string, $short-string">
                            <xsl:copy>
                                <xsl:attribute name="outer-loop" select="$loop-counter"/>
                                <xsl:value-of select="."/>
                            </xsl:copy>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$diagnostics-on">
                            <xsl:message
                                select="'No matches, out of vertical stops, down to substring lengths of ', $length-of-short-substring"
                            />
                        </xsl:if>
                        <xsl:copy-of select="$long-string, $short-string"/>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:diff-inner-loop">
        <xsl:param name="short-string" as="element()?"/>
        <xsl:param name="long-string" as="element()?"/>
        <xsl:param name="starting-locs-to-check" as="xs:integer*"/>
        <xsl:param name="length-of-short-substring" as="xs:integer"/>
        <xsl:param name="search-prefix" as="xs:string?"/>
        <xsl:param name="search-suffix" as="xs:string?"/>
        <xsl:param name="loop-counter" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="count($starting-locs-to-check) lt 1"/>
            <xsl:when test="$loop-counter ge $loop-tolerance">
                <xsl:message
                    select="concat('Inner loop cannot go beyond ', xs:string($loop-tolerance), ' passes')"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="this-search-string"
                    select="tan:escape(substring($short-string, $starting-locs-to-check[1], $length-of-short-substring))"/>
                <xsl:variable name="this-search-regex"
                    select="concat($search-prefix, $this-search-string, $search-suffix)"/>
                <xsl:variable name="this-search" as="element()*">
                    <xsl:if test="string-length($this-search-string) gt 0">
                        <xsl:analyze-string select="$long-string" regex="{$this-search-regex}">
                            <xsl:matching-substring>
                                <common inner-loop="{$loop-counter}">
                                    <xsl:value-of select="."/>
                                </common>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:element name="{name($long-string)}">
                                    <xsl:attribute name="loop" select="$loop-counter"/>
                                    <xsl:value-of select="."/>
                                </xsl:element>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="diagnostics-on" as="xs:boolean" select="contains($short-string, 'PRIVACY IS PROT')"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'diagnostics on for tan:diff-inner-loop()'"/>
                    <xsl:message select="'inner loop number ', $loop-counter"/>
                    <xsl:message select="'$short-string:', tan:trim-long-text($short-string, 11)"/>
                    <xsl:message select="'$long-string:', tan:trim-long-text($long-string, 11)"/>
                    <xsl:message select="'starting locs to check:', $starting-locs-to-check"/>
                    <xsl:message select="'$length-of-short-substring:', $length-of-short-substring"/>
                    <xsl:message select="'search string:', $this-search-string"/>
                    <xsl:message select="'search regex:', $this-search-regex"/>
                    <xsl:message select="'search result: ', serialize($this-search)"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="exists($this-search/self::tan:common)">
                        <result short-search-start="{$starting-locs-to-check[1]}"
                            short-search-length="{$length-of-short-substring}">
                            <xsl:copy-of select="$this-search"/>
                        </result>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of
                            select="tan:diff-inner-loop($short-string, $long-string, $starting-locs-to-check[position() gt 1], $length-of-short-substring, $search-prefix, $search-suffix, $loop-counter + 1)"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:collate" as="element()">
        <!-- one parameter version of full one below -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:variable name="these-labels"
            select="
                for $i in (1 to count($strings))
                return
                    xs:string($i)"/>
        <xsl:copy-of select="tan:collate($strings, $these-labels)"/>
    </xsl:function>
    <xsl:function name="tan:collate" as="element()">
        <!-- Input: any number of strings -->
        <!-- Output: an element with <c> and <u w="[WITNESS NUMBERS]">, showing where there are common strings and where there are departures. At the beginning are <witness>es identifying the numbers, and providing basic statistics about how much each pair of witnesses agree. -->
        <!-- This function was written to deal with multiple OCR results of the same page of text, to find agreement wherever possible. -->
        <!-- This function was rewritten in 2020 as an XSLT 3.0 function, with 5-arity. -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:param name="labels" as="xs:string*"/>

        <xsl:variable name="valid-strings" as="xs:string*">
            <xsl:for-each select="$strings">
                <xsl:choose>
                    <xsl:when test="string-length(.) lt 1">
                        <xsl:message
                            select="'input', position(), 'is a zero-length string and is therefore ignored'"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="count($valid-strings) lt 2">
                <!-- If fewer than two strings are given, a collation can't be done -->
                <collation>
                    <witness>
                        <xsl:value-of select="$labels[1]"/>
                    </witness>
                    <c w="{$labels[1]}">
                        <xsl:value-of select="$valid-strings[1]"/>
                    </c>
                </collation>
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 1: run diff against each pair of strings -->
                <xsl:variable name="all-diffs" as="element()*">
                    <xsl:for-each select="$labels[position() gt 1]">
                        <xsl:variable name="text1" select="."/>
                        <xsl:variable name="this-pos" select="position() + 1"/>
                        <xsl:for-each select="$labels[position() lt $this-pos]">
                            <xsl:variable name="text2" select="."/>
                            <xsl:variable name="that-pos" select="position()"/>
                            <xsl:variable name="this-diff"
                                select="tan:diff($valid-strings[$this-pos], $valid-strings[$that-pos], false())"/>
                            <diff a="{$text1}" b="{$text2}">
                                <xsl:copy-of select="$this-diff/*"/>
                            </diff>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <!-- Step 2: sort by greatest amount of commonality -->
                <xsl:variable name="diffs-sorted" as="element()*">
                    <xsl:for-each-group select="$all-diffs"
                        group-by="
                            sum((for $i in tan:common
                            return
                                string-length($i))) div (sum((for $j in tan:*
                            return
                                string-length($j))) - (sum((for $k in (tan:a, tan:b)
                            return
                                string-length($k))) div 2))">
                        <xsl:sort order="descending" select="current-grouping-key()"/>
                        <xsl:for-each select="current-group()">
                            <xsl:copy>
                                <xsl:attribute name="commonality" select="current-grouping-key()"/>
                                <xsl:copy-of select="@* | node()"/>
                            </xsl:copy>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </xsl:variable>
                <!-- Step 3: get the sequence in which versions should be processed -->
                <xsl:variable name="collate-order"
                    select="
                        distinct-values(for $i in $diffs-sorted
                        return
                            ($i/@a, $i/@b))"/>
                <!-- Step 4: set up the first collation diff -->
                <xsl:variable name="first-collation" as="element()">
                    <xsl:apply-templates select="$diffs-sorted[1]" mode="diff-to-collation">
                        <xsl:with-param name="w1" select="$collate-order[1]" tunnel="yes"/>
                        <xsl:with-param name="w2" select="$collate-order[2]" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- Step 5: run the collation loop -->
                <xsl:variable name="full-collation"
                    select="
                        tan:collate-loop-outer($first-collation, (for $i in $collate-order[position() gt 2],
                            $j in index-of($labels, $i)
                        return
                            $valid-strings[$j]), $collate-order[position() gt 2])"/>
                <!-- Step 6: consolidate, stamp the collation -->
                <xsl:variable name="consolidated-collation" as="element()">
                    <collation>
                        <xsl:for-each-group select="$full-collation/*" group-adjacent="name(.)">
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'witness'">
                                    <xsl:for-each select="current-group()">
                                        <xsl:variable name="this-witness" select="text()"/>
                                        <xsl:copy>
                                            <xsl:attribute name="id" select="$this-witness"/>
                                            <xsl:for-each select="$collate-order">
                                                <xsl:variable name="this-partner" select="."/>
                                                <xsl:variable name="this-diff"
                                                  select="$diffs-sorted[(@a = $this-partner and @b = $this-witness) or (@a = $this-witness and @b = $this-partner)]"/>
                                                <commonality with="{$this-partner}">
                                                  <xsl:value-of
                                                  select="
                                                            if (exists($this-diff)) then
                                                                $this-diff/@commonality
                                                            else
                                                                1.0"
                                                  />
                                                </commonality>
                                            </xsl:for-each>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="current-grouping-key() = 'u'">
                                    <xsl:variable name="this-group" as="element()">
                                        <group>
                                            <xsl:for-each-group select="current-group()"
                                                group-adjacent="@w">
                                                <u>
                                                  <xsl:copy-of select="current-group()/@*"/>
                                                  <xsl:value-of
                                                  select="string-join(current-group(), '')"/>
                                                </u>
                                            </xsl:for-each-group>
                                        </group>
                                    </xsl:variable>
                                    <xsl:for-each-group select="$this-group/*"
                                        group-adjacent="
                                            tan:most-common-item-count(for $i in (@w, preceding-sibling::*/@w)
                                            return
                                                tokenize($i, ' '))">
                                        <xsl:for-each-group select="current-group()" group-by=".">
                                            <u w="{string-join(current-group()/@w,' ')}">
                                                <xsl:value-of select="current-grouping-key()"/>
                                            </u>
                                        </xsl:for-each-group>
                                    </xsl:for-each-group>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="current-group()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each-group>
                    </collation>
                </xsl:variable>
                <!-- Step 7: determine, for groups of <u>s, what the base text should be -->
                <xsl:variable name="collation-with-base-marked" as="element()">
                    <collation>
                        <xsl:for-each-group select="$consolidated-collation/*"
                            group-adjacent="name(.)">
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'u'">
                                    <xsl:variable name="witness-count-max"
                                        select="
                                            max((for $i in current-group()
                                            return
                                                count(tokenize($i/@w, ' '))))"/>
                                    <xsl:variable name="this-group" as="element()">
                                        <group>
                                            <xsl:copy-of select="current-group()"/>
                                        </group>
                                    </xsl:variable>
                                    <xsl:variable name="most-probable-base"
                                        select="($this-group/*[count(tokenize(@w, ' ')) = $witness-count-max])[1]"/>
                                    <xsl:copy-of select="$most-probable-base/preceding-sibling::*"/>
                                    <u base="">
                                        <xsl:copy-of select="$most-probable-base/@w"/>
                                        <xsl:value-of select="$most-probable-base/text()"/>
                                    </u>
                                    <xsl:copy-of select="$most-probable-base/following-sibling::*"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="current-group()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each-group>
                    </collation>
                </xsl:variable>
                
                <!-- diagnostics, results -->
                <xsl:variable name="diagnostics-on" select="false()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'diagnostics on for tan:collate()'"/>
                    <xsl:message select="'all diffs: ', $all-diffs"/>
                    <xsl:message select="'diffs sorted: ', $diffs-sorted"/>
                    <xsl:message select="'collate order: ', $collate-order"/>
                    <xsl:message select="'first collation: ', $first-collation"/>
                    <xsl:message select="'full collation: ', $full-collation"/>
                    <xsl:message select="'consolidated collation: ', $consolidated-collation"/>
                </xsl:if>
                
                <xsl:copy-of select="$collation-with-base-marked"/>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="tan:diff" mode="diff-to-collation">
        <xsl:param name="w1" tunnel="yes"/>
        <xsl:param name="w2" tunnel="yes"/>
        <collation>
            <witness>
                <xsl:value-of select="$w1"/>
            </witness>
            <witness>
                <xsl:value-of select="$w2"/>
            </witness>
            <xsl:apply-templates mode="#current"/>
        </collation>
    </xsl:template>
    <xsl:template match="tan:common" mode="diff-to-collation">
        <c length="{string-length(.)}">
            <xsl:value-of select="."/>
        </c>
    </xsl:template>
    <xsl:template match="tan:a" mode="diff-to-collation">
        <xsl:param name="w1" tunnel="yes"/>
        <u w="{$w1}">
            <xsl:value-of select="."/>
        </u>
    </xsl:template>
    <xsl:template match="tan:b" mode="diff-to-collation">
        <xsl:param name="w2" tunnel="yes"/>
        <u w="{$w2}">
            <xsl:value-of select="."/>
        </u>
    </xsl:template>

    <xsl:function name="tan:collate-loop-outer" as="element()">
        <!-- Input: a collation element (see template mode diff-to-collation), some strings to process, and corresponding string labels -->
        <!-- Output: a series of collation elements, marking where there is commonality and differences -->
        <!-- This function supports the XSLT 2.0 version of tan:collate() -->
        <xsl:param name="collation-so-far" as="element()"/>
        <xsl:param name="strings-to-process" as="xs:string*"/>
        <xsl:param name="string-labels" as="xs:string*"/>
        <!-- Step 1: can the loop even be run? It can't if there aren't strings to process, or there is no commonality in the collation -->
        <xsl:choose>
            <!-- If there are no more strings to process, then end the loop -->
            <xsl:when test="count($strings-to-process) lt 1">
                <xsl:sequence select="$collation-so-far"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="new-collation" as="element()">
                    <collation>
                        <xsl:copy-of select="$collation-so-far/tan:witness"/>
                        <witness>
                            <xsl:value-of select="$string-labels[1]"/>
                        </witness>
                        <xsl:copy-of
                            select="tan:collate-loop-inner($collation-so-far, $strings-to-process[1], $string-labels[1])"
                        />
                    </collation>
                </xsl:variable>
                
                <xsl:variable name="diagnostics-on" select="false()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'Diagnostics on, tan:collate-loop-outer()'"/>
                    <xsl:message select="'Collation so far: ', serialize($collation-so-far)"/>
                    <xsl:message
                        select="
                            'Strings-to-process: (', count($strings-to-process), '): ',
                            for $i in $strings-to-process
                            return
                                tan:trim-long-text($i, 40)"
                    />
                    <xsl:message select="'String labels: (', count($string-labels), '): ', $string-labels"/>
                    <xsl:message select="'New collation: ', serialize($new-collation)"/>
                </xsl:if>
                
                <xsl:sequence
                    select="tan:collate-loop-outer($new-collation, $strings-to-process[position() gt 1], $string-labels[position() gt 1])"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:collate-loop-inner" as="element()*">
        <!-- Input: a collation element (see template mode diff-to-collation), one string to process, and the corresponding string label -->
        <!-- Output: a series of collation elements, marking where there is commonality and differences -->
        <!-- This inner loop returns only the children of the collation element; the outer loop handles the parent element -->
        <!-- This function supports the XSLT 2.0 version of tan:collate() -->
        <xsl:param name="collation-so-far" as="element()"/>
        <xsl:param name="string-to-process" as="xs:string?"/>
        <xsl:param name="string-label" as="xs:string?"/>
        <xsl:choose>
            <!-- If the collation so far has no common elements, then end the loop -->
            <xsl:when test="not(exists($collation-so-far/tan:c))">
                <xsl:copy-of select="$collation-so-far/tan:u[string-length(.) gt 0]"/>
                <xsl:if test="string-length($string-to-process) gt 0">
                    <u w="{$string-label}">
                        <xsl:value-of select="$string-to-process"/>
                    </u>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- Step 2a: split $collation-so-far into three: the longest <c> and what precedes and what follows -->
                <xsl:variable name="collation-longest-common-length"
                    select="
                        xs:string(max((for $i in $collation-so-far/tan:c/@length
                        return
                            xs:integer($i))))"/>
                <xsl:variable name="collation-longest-common"
                    select="($collation-so-far/tan:c[@length = $collation-longest-common-length])[1]"/>
                <!-- Step 2b: get the diff between the longest collation segment and the next string to be processed -->
                <xsl:variable name="this-diff"
                    select="tan:diff($collation-longest-common, $string-to-process, false())"/>

                <!-- Step 3: are the results complete, or does the loop need to be run again? -->
                <xsl:choose>
                    <!-- If there's no string to process, or if there's no match, then every stretch of text is unique, including the longest collation segment. Mark them as such and end. -->
                    <xsl:when
                        test="(string-length($string-to-process) lt 1) or not(exists($this-diff/tan:common))">
                        <xsl:for-each
                            select="$collation-so-far/(tan:c, tan:u)[string-length(.) gt 0]">
                            <u
                                w="{if (exists(@w)) then @w else string-join($collation-so-far/tan:witness,' ')}">
                                <xsl:value-of select="."/>
                            </u>
                        </xsl:for-each>
                        <u w="{$string-label}">
                            <xsl:value-of select="$string-to-process"/>
                        </u>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- There's a match. Find the longest common match. Isolate the heads and tails of both strings. Add the collations parts to the collation's head and tail. Run the collation's head against the string head and the collation's tail against the string tail. -->
                        <!-- Step 4: focus on the longest common match -->
                        <xsl:variable name="this-diff-common-length-max"
                            select="
                                max((for $i in $this-diff/tan:common
                                return
                                    string-length($i)))"/>
                        <xsl:variable name="this-diff-longest-match"
                            select="($this-diff/tan:common[string-length(.) = $this-diff-common-length-max])[1]"/>
                        <xsl:variable name="string-head"
                            select="string-join($this-diff-longest-match/preceding-sibling::*/(self::* except self::*:a), '')"/>
                        <xsl:variable name="string-tail"
                            select="string-join($this-diff-longest-match/following-sibling::*/(self::* except self::*:a), '')"/>
                        <xsl:variable name="clc-head"
                            select="string-join($this-diff-longest-match/preceding-sibling::*/(self::* except self::*:b), '')"/>
                        <xsl:variable name="clc-tail"
                            select="string-join($this-diff-longest-match/following-sibling::*/(self::* except self::*:b), '')"/>
                        <xsl:variable name="collation-head" as="element()">
                            <collation>
                                <xsl:copy-of select="$collation-longest-common/preceding-sibling::*"/>
                                <xsl:if test="string-length($clc-head) gt 0">
                                    <c length="{string-length($clc-head)}">
                                        <xsl:value-of select="$clc-head"/>
                                    </c>
                                </xsl:if>
                            </collation>
                        </xsl:variable>
                        <xsl:variable name="collation-tail" as="element()">
                            <collation>
                                <xsl:copy-of select="$collation-so-far/tan:witness"/>
                                <xsl:if test="string-length($clc-tail) gt 0">
                                    <c length="{string-length($clc-tail)}">
                                        <xsl:value-of select="$clc-tail"/>
                                    </c>
                                </xsl:if>
                                <xsl:copy-of select="$collation-longest-common/following-sibling::*"
                                />
                            </collation>
                        </xsl:variable>
                        
                        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
                        <xsl:if test="$diagnostics-on">
                            <xsl:message select="'diagnostics on for tan:collate-loop-inner()'"/>
                            <xsl:message
                                select="'collation longest common length: ', $collation-longest-common-length"/>
                            <xsl:message select="'collation longest common: ', $collation-longest-common"/>
                            <xsl:message select="'this diff: ', $this-diff"/>
                            <xsl:message
                                select="'common length max of this diff: ', $this-diff-common-length-max"/>
                            <xsl:message
                                select="'longest match in this diff: ', $this-diff-longest-match"/>
                            <xsl:message select="'string head: ', $string-head"/>
                            <xsl:message select="'string tail: ', $string-tail"/>
                            <xsl:message select="'head of collation longest common: ', $clc-head"/>
                            <xsl:message select="'tail of collation longest common: ', $clc-tail"/>
                            <xsl:message select="'collation head: ', $collation-head"/>
                            <xsl:message select="'collation tail: ', $collation-tail"/>
                        </xsl:if>
                        
                        <xsl:copy-of
                            select="tan:collate-loop-inner($collation-head, $string-head, $string-label)"/>
                        <c length="{$this-diff-common-length-max}">
                            <xsl:value-of select="$this-diff-longest-match"/>
                        </c>
                        <xsl:copy-of
                            select="tan:collate-loop-inner($collation-tail, $string-tail, $string-label)"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
