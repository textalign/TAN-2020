<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library extended string functions. -->
   
   <xsl:function name="tan:segment-string" as="xs:string*" visibility="public">
      <!-- 2-arity version of the more complete function, below -->
      <xsl:param name="string-to-segment" as="xs:string?"/>
      <xsl:param name="segment-portions" as="xs:decimal*"/>
      <xsl:sequence select="tan:segment-string($string-to-segment, $segment-portions, '\s+')"/>
   </xsl:function>
   
   <xsl:function name="tan:segment-string" as="xs:string*" visibility="public">
      <!-- Input: a string, a sequence of doubles from 0 through 1, a regular expression -->
      <!-- Output: the string divided into segments proportionate to the doubles, with divisions allowed only by the regular expression -->
      <xsl:param name="string-to-segment" as="xs:string?"/>
      <xsl:param name="segment-portions" as="xs:decimal*"/>
      <xsl:param name="break-at-regex" as="xs:string"/>
      <xsl:variable name="snap-marker" as="xs:string" select="
            if (string-length($break-at-regex) lt 1) then
               '\s+'
            else
               $break-at-regex"/>
      <xsl:variable name="input-length" as="xs:integer" select="string-length($string-to-segment)"/>
      <xsl:variable name="new-content-tokenized" as="xs:string*"
         select="tan:chop-string($string-to-segment, $snap-marker)"/>
      
      <xsl:choose>
         <xsl:when test="$input-length lt 1"/>
         <xsl:otherwise>
            <xsl:variable name="new-content-map" as="map(xs:decimal, xs:string)">
               <xsl:map>
                  <xsl:iterate select="$new-content-tokenized">
                     <xsl:param name="last-pos" as="xs:integer" select="0"/>
                     <xsl:variable name="this-length" select="string-length(.)" as="xs:integer"/>
                     <xsl:variable name="new-pos" as="xs:integer" select="$last-pos + $this-length"/>
                     <xsl:map-entry key="($last-pos + 1) div $input-length" select="."/>
                     <xsl:next-iteration>
                        <xsl:with-param name="last-pos" select="$new-pos" as="xs:integer"/>
                     </xsl:next-iteration>
                  </xsl:iterate>
               </xsl:map>
            </xsl:variable>
            <xsl:variable name="new-content-keys" select="map:keys($new-content-map)" as="xs:decimal+"/>
            <xsl:iterate select="sort(distinct-values(($segment-portions, 1)))">
               <xsl:param name="prev-portion" as="xs:decimal" select="-1"/>
               <xsl:variable name="this-portion" select="."/>
               <xsl:variable name="these-keys" select="$new-content-keys[. gt $prev-portion][. le $this-portion]"/>
               <xsl:choose>
                  <xsl:when test=". le 0 or . gt 1"/>
                  <xsl:otherwise>
                     <xsl:value-of select="
                        string-join((for $i in sort($these-keys)
                        return
                        $new-content-map($i)))"/>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:next-iteration>
                  <xsl:with-param name="prev-portion" select="."/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:function name="tan:namespace" as="xs:string*" visibility="public">
      <!-- Input: any strings representing a namespace prefix or uri -->
      <!-- Output: the corresponding prefix or uri whenever a match is found in the global variable -->
      <xsl:param name="prefix-or-uri" as="xs:string*"/>
      <xsl:for-each select="$prefix-or-uri">
         <xsl:variable name="this-string" select="."/>
         <xsl:sequence
            select="$tan:namespaces-and-prefixes/*[@* = $this-string]/(@*[not(. = $this-string)])[1]"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:glob-to-regex" as="xs:string*" visibility="public">
      <!-- Input: any strings that follow a glob-like syntax -->
      <!-- Output: the strings converted to regular expressions -->
      <xsl:param name="globs" as="xs:string*"/>
      <xsl:for-each select="$globs">
         <!-- escape special regex characters that aren't special glob characters -->
         <xsl:variable name="pass-1" select="replace(., '([\.\\\|\^\$\+\{\}\(\)])', '\$1')"/>
         <!-- convert glob * -->
         <xsl:variable name="pass-2" select="replace($pass-1, '\*', '.*')"/>
         <!-- convert glob ? -->
         <xsl:variable name="pass-3" select="replace($pass-2, '\?', '.')"/>
         <!-- make sure the results match either an entire filename or an entire path -->
         <xsl:value-of select="'^' || $pass-3 || '$|/' || $pass-3 || '$'"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:acronym" as="xs:string?" visibility="public">
      <!-- Input: any strings -->
      <!-- Output: the acronym of those strings (initial letters joined without spaces) -->
      <!-- Example: "The Cat in the Hat" - > "TCitH" -->
      <xsl:param name="string-input" as="xs:string?"/>
      <xsl:variable name="initials" as="xs:string*" select="
            for $i in tokenize($string-input, '\s+')
            return
               substring($i, 1, 1)"/>
      <xsl:value-of select="string-join($initials, '')"/>
   </xsl:function>
   
   
   <xsl:function name="tan:batch-replacement-messages" as="xs:string?" visibility="private">
      <!-- Input: any batch replacement element -->
      <!-- Output: a string explaining what it does -->
      <!-- This function is useful for reporting back to users in a readable format what changes are rendered -->
      <xsl:param name="batch-replace-element" as="element()?"/>
      <xsl:variable name="message-components" as="xs:string*">
         <xsl:if
            test="exists($batch-replace-element/@message) or exists($batch-replace-element/@flags)">
            <xsl:if test="exists($batch-replace-element/@message)">
               <xsl:value-of select="$batch-replace-element/@message"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 's')">
               <xsl:value-of select="' (dot-all mode)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'm')">
               <xsl:value-of select="' (multi-line mode)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'i')">
               <xsl:value-of select="' (case insensitive)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'x')">
               <xsl:value-of select="' (ignore regex whitespaces)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'q')">
               <xsl:value-of select="' (ignore special characters)'"/>
            </xsl:if>
            <xsl:value-of select="': '"/>
         </xsl:if>
         <xsl:value-of
            select="'PATTERN: ' || $batch-replace-element/@pattern || '  REPLACEMENT: ' || $batch-replace-element/@replacement"/>
         
      </xsl:variable>
      <xsl:value-of select="string-join($message-components)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:batch-replace-advanced" as="item()*" visibility="public">
      <!-- Input: a string; a sequence of elements <[ANY NAME] pattern="" [flags=""]>[ANY CONTENT]</[ANY NAME]> -->
      <!-- Output: a sequence of items, with instances of @pattern replaced by the content of the elements -->
      <!-- This is a more advanced form of tan:batch-replace(), in that it allows text to be replaced by elements. -->
      <!-- The function was devised to convert raw text into TAN-T. Textual references can be turned into <div n=""/> anchors, and the result can then be changed into a traditional hierarchy. -->
      <xsl:param name="string" as="xs:string?"/>
      <xsl:param name="replace-elements" as="element()*"/>
      <xsl:choose>
         <xsl:when test="not(exists($replace-elements))">
            <xsl:value-of select="$string"/>
         </xsl:when>
         <xsl:when test="string-length($replace-elements[1]/@pattern) lt 1">
            <xsl:copy-of
               select="tan:batch-replace-advanced($string, $replace-elements[position() gt 1])"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:analyze-string select="$string" regex="{$replace-elements[1]/@pattern}" flags="{$replace-elements[1]/@flags}">
               <xsl:matching-substring>
                  <xsl:apply-templates select="$replace-elements[1]/node()" mode="tan:batch-replace-advanced">
                     <xsl:with-param name="regex-zero" tunnel="yes" select="."/>
                     <xsl:with-param name="regex-groups" tunnel="yes"
                        select="
                        for $i in (1 to 20)
                        return
                        regex-group($i)"
                     />
                  </xsl:apply-templates>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <!-- Anything that doesn't match should be processed with the next replace element -->
                  <xsl:copy-of
                     select="tan:batch-replace-advanced(., $replace-elements[position() gt 1])"/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:mode name="tan:batch-replace-advanced" 
      on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:batch-replace-advanced">
      <xsl:copy>
         <xsl:apply-templates select="@* | node()" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="@*" mode="tan:batch-replace-advanced">
      <xsl:param name="regex-zero" as="xs:string" tunnel="yes"/>
      <xsl:param name="regex-groups" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="new-value" as="xs:string*">
         <xsl:analyze-string select="." regex="\$(\d+)">
            <xsl:matching-substring>
               <xsl:variable name="this-regex-no" select="number(regex-group(1))"/>
               <xsl:value-of select="$regex-groups[$this-regex-no]"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:attribute name="{name(.)}" select="string-join($new-value, '')"/>
   </xsl:template>
   
   <xsl:template match="text()" mode="tan:batch-replace-advanced">
      <xsl:param name="regex-zero" as="xs:string" tunnel="yes"/>
      <xsl:param name="regex-groups" as="xs:string*" tunnel="yes"/>
      <xsl:choose>
         <!-- omit whitespace text -->
         <xsl:when test="not(matches(., '\S'))"/>
         <xsl:otherwise>
            <xsl:analyze-string select="." regex="\$(\d+)">
               <xsl:matching-substring>
                  <xsl:variable name="this-regex-no" select="number(regex-group(1))"/>
                  <xsl:value-of select="$regex-groups[$this-regex-no]"/>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:function name="tan:normalize-unicode" as="item()*">
      <!-- Input: any items -->
      <!-- Output: the same items, but with all unicode normalized -->
      <xsl:param name="input" as="item()*"/>
      <xsl:apply-templates select="$input" mode="tan:normalize-unicode"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:normalize-unicode" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:normalize-unicode">
      <xsl:value-of select="normalize-unicode(.)"/>
   </xsl:template>
   
   
   <xsl:variable name="tan:english-prepositions" as="xs:string+"
      select="('aboard', 'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among', 'anti', 'around', 'as', 'at', 'before', 'behind', 'below', 'beneath', 'beside', 'besides', 'between', 'beyond', 'but', 'by', 'concerning', 'considering', 'despite', 'down', 'during', 'except', 'excepting', 'excluding', 'following', 'for', 'from', 'in', 'inside', 'into', 'like', 'minus', 'near', 'of', 'off', 'on', 'onto', 'opposite', 'outside', 'over', 'past', 'per', 'plus', 'regarding', 'round', 'save', 'since', 'than', 'through', 'to', 'toward', 'towards', 'under', 'underneath', 'unlike', 'until', 'up', 'upon', 'versus', 'via', 'with', 'within', 'without')"
   />
   <xsl:variable name="tan:english-articles" as="xs:string+" select="('a', 'the')"/>
   
   <xsl:function name="tan:title-case" as="xs:string*" visibility="public">
      <!-- Input: a sequence of strings -->
      <!-- Output: each string set in title case, following the conventions of English (one of the only languages that bother with title-case) -->
      <!-- According to Chicago rules of title casing, the first and last words are always capitalized, and interior words are capitalzied unless they are a preposition or article -->
      <xsl:param name="string-to-convert" as="xs:string*"/>
      <xsl:for-each select="$string-to-convert">
         <xsl:variable name="pass-1" as="element()">
            <phrase>
               <xsl:analyze-string select="." regex="\w+">
                  <xsl:matching-substring>
                     <word>
                        <xsl:choose>
                           <xsl:when test=". = ($tan:english-prepositions, $tan:english-articles)">
                              <xsl:value-of select="lower-case(.)"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:value-of select="tan:initial-upper-case(.)"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </word>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <non-word>
                        <xsl:value-of select="."/>
                     </non-word>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </phrase>
         </xsl:variable>
         <xsl:variable name="pass-2" as="element()">
            <xsl:apply-templates select="$pass-1" mode="tan:title-case"/>
         </xsl:variable>
         <xsl:value-of select="string-join($pass-2/*, '')"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:mode name="tan:title-case" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:word[1] | tan:word[last()]" mode="tan:title-case">
      <xsl:copy>
         <xsl:value-of select="tan:initial-upper-case(.)"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:initial-upper-case" as="xs:string*" visibility="public">
      <!-- Input: any strings -->
      <!-- Output: each string with the initial letters capitalized and the rest set lower-case -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:variable name="non-letter-regex">\P{L}</xsl:variable>
      <xsl:for-each select="$strings">
         <xsl:variable name="pass-1" as="xs:string*">
            <xsl:analyze-string select="." regex="^{$non-letter-regex}+">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="upper-case(substring(., 1, 1)) || lower-case(substring(., 2))"/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:value-of select="string-join($pass-1)"/>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:commas-and-ands" as="xs:string?" visibility="public">
      <!-- One-parameter version of the full one below -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:value-of select="tan:commas-and-ands($input-strings, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:commas-and-ands" as="xs:string?" visibility="public">
      <!-- Input: sequences of strings -->
      <!-- Output: the strings joined together with , and 'and' -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:param name="oxford-comma" as="xs:boolean"/>
      <xsl:variable name="input-string-count" select="count($input-strings)"/>
      <xsl:variable name="results" as="xs:string*">
         <xsl:for-each select="$input-strings">
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:value-of select="."/>
            <xsl:if test="$input-string-count gt 2">
               <xsl:choose>
                  <xsl:when test="$this-pos lt ($input-string-count - 1)">,</xsl:when>
                  <xsl:when test="$this-pos = ($input-string-count - 1) and $oxford-comma">,</xsl:when>
               </xsl:choose>
            </xsl:if>
            <xsl:if test="$this-pos lt $input-string-count">
               <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="$input-string-count gt 1 and $this-pos = ($input-string-count - 1)"
               >and </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($results)"/>
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regex" as="xs:boolean" visibility="public">
      <!-- 2-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, (), ())"
      />
   </xsl:function>
   
   <xsl:function name="tan:filename-satisfies-regex" as="xs:boolean" visibility="private">
      <!-- 2-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, (), 'i')"
      />
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regexes" as="xs:boolean" visibility="public">
      <!-- 3-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, $string-must-not-match-regex, ())"
      />
   </xsl:function>
   
   <xsl:function name="tan:filename-satisfies-regexes" as="xs:boolean" visibility="private">
      <!-- 3-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, $string-must-not-match-regex, 'i')"
      />
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regexes" as="xs:boolean" visibility="public">
      <!-- Input: a string value; an optional regex the string must match; an optional regex the string must not match -->
      <!-- Output: whether the string satisfies the two regex conditions; if either regex is empty, true will be returned -->
      <!-- If the input string is less than zero length, the function returns false -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:param name="flags" as="xs:string?"/>
      <xsl:variable name="test-1" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="string-length($string-to-test) lt 1">
               <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when
               test="not(exists($string-must-match-regex)) or string-length($string-must-match-regex) lt 1">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="matches($string-to-test, $string-must-match-regex, $flags)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="test-2" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="string-length($string-to-test) lt 1">
               <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when
               test="not(exists($string-must-not-match-regex)) or string-length($string-must-not-match-regex) lt 1">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of
                  select="not(matches($string-to-test, $string-must-not-match-regex, $flags))"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="$test-1 and $test-2"/>
   </xsl:function>
   
   
   <xsl:function name="tan:reverse-string" as="xs:string?" visibility="public">
      <!-- Input: any string -->
      <!-- Output: the string in reverse order -->
      <xsl:param name="string-to-reverse" as="xs:string?"/>
      <xsl:sequence select="codepoints-to-string(reverse(string-to-codepoints($string-to-reverse)))"/>
   </xsl:function>
   
   
   
   <xsl:function name="tan:possible-bibliography-id" as="xs:string" visibility="private">
      <!-- Input: a string with a bibliographic entry -->
      <!-- Output: unique values of the two longest words and the first numeral that looks like a date -->
      <!-- When working with bibliographical data, it is next to impossible to rely upon an exact match to tell whether two citations refer to the same item. -->
      <!-- Many times, however, the longest word or two, plus the four-digit date, are good ways to try to find matches. -->
      <xsl:param name="bibl-cit" as="xs:string"/>
      <xsl:variable name="this-citation-dates" as="xs:string*">
         <xsl:analyze-string select="$bibl-cit" regex="^\d\d\d\d\D|\D\d\d\d\d\D|\D\d\d\d\d$">
            <xsl:matching-substring>
               <xsl:value-of select="replace(., '\D', '')"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="this-citation-longest-words" as="xs:string*">
         <xsl:for-each select="tokenize($bibl-cit, '\W+')">
            <xsl:sort select="string-length(.)" order="descending"/>
            <xsl:if test="not(lower-case(.) = $tan:bibliography-words-to-ignore)">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of
         select="string-join(distinct-values(($this-citation-longest-words[position() lt 3], $this-citation-dates[1])), ' ')"
      />
   </xsl:function>
   
   

</xsl:stylesheet>