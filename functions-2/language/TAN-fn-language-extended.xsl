<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">

   <!-- TAN Function Library extended language functions. -->

   <xsl:function name="tan:lm-data" as="element()*" visibility="public">
      <!-- Input: token value; a language code -->
      <!-- Output: <lm> data for that token value from any available resources -->
      <xsl:param name="token-value" as="xs:string?"/>
      <xsl:param name="lang-codes" as="xs:string*"/>

      <!-- First, look in the local language catalog and get relevant TAN-A-lm files -->
      <xsl:variable name="lang-catalogs" select="tan:lang-catalog($lang-codes)"
         as="document-node()*"/>
      <xsl:variable name="these-tan-a-lm-files" as="document-node()*">
         <xsl:for-each select="$lang-catalogs">
            <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
            <xsl:for-each select="
                  collection/doc[(not(exists(tan:tok-is)) and not(exists(tan:tok-starts-with)))
                  or
                  (tan:tok-is = $token-value)
                  or (some $i in tan:tok-starts-with
                     satisfies starts-with($token-value, $i))]">
               <xsl:variable name="this-uri" select="resolve-uri(@href, string($this-base-uri))"/>
               <xsl:if test="doc-available($this-uri)">
                  <xsl:sequence select="doc($this-uri)"/>
               </xsl:if>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>

      <!-- Look for easy, exact matches -->
      <xsl:variable name="lex-val-matches" select="
            for $i in $these-tan-a-lm-files
            return
               key('tan:get-ana', $token-value, $i)"/>

      <!-- If there's no exact match, look for a near match -->
      <xsl:variable name="this-string-approx" select="tan:string-base($token-value)"/>
      <xsl:variable name="lex-rgx-and-approx-matches" select="
            $these-tan-a-lm-files/tan:TAN-A-lm/tan:body/tan:ana[tan:tok[@val = $this-string-approx or (if (string-length(@rgx) gt 0)
            then
               matches($token-value, @rgx)
            else
               false())]]"/>

      <!-- If there's not even a near match, see if there's a search service -->
      <xsl:variable name="lex-matches-via-search" as="element()*">
         <xsl:if test="matches($lang-codes, '^(lat|grc)')">
            <xsl:variable name="this-raw-search" select="tan:search-morpheus($token-value)"/>
            <xsl:copy-of select="tan:search-results-to-claims($this-raw-search, 'morpheus')/*"/>
         </xsl:if>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="exists($lex-val-matches)">
            <xsl:sequence select="$lex-val-matches"/>
         </xsl:when>
         <xsl:when test="exists($lex-rgx-and-approx-matches)">
            <xsl:sequence select="$lex-rgx-and-approx-matches"/>
         </xsl:when>
         <xsl:when test="exists($lex-matches-via-search)">
            <xsl:sequence select="$lex-matches-via-search"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="not(exists($these-tan-a-lm-files))">
               <xsl:message select="'No local TAN-A-lm files found for', $lang-codes"/>
            </xsl:if>
            <xsl:message select="'No data found for', $token-value, 'in language', $lang-codes"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>


   
   <xsl:function name="tan:merge-anas" as="element()?" visibility="private">
      <!-- Input: a set of <ana>s that should be merged; a list of strings to which <tok>s should be restricted -->
      <!-- Output: the merger of the <ana>s, with @cert recalibrated and all <tok>s merged -->
      <!-- This function presumes that every relevant <tok> has a @val, and that values of <l> and <m> have been normalized -->
      
      <xsl:param name="anas-to-merge" as="element(tan:ana)*"/>
      <xsl:param name="regard-only-those-toks-that-have-what-vals" as="xs:string*"/>
      <xsl:variable name="ana-tok-counts" as="xs:integer*">
         <xsl:for-each select="$anas-to-merge">
            <xsl:variable name="toks-of-interest"
               select="tan:tok[@val = $regard-only-those-toks-that-have-what-vals]"/>
            <xsl:choose>
               <xsl:when test="exists(@tok-pop)">
                  <xsl:value-of select="@tok-pop"/>
               </xsl:when>
               <xsl:when test="exists($toks-of-interest)">
                  <xsl:value-of select="count($toks-of-interest)"/>
               </xsl:when>
               <xsl:when test="exists(tan:lm)">
                  <xsl:value-of
                     select="
                     sum(for $i in tan:lm
                     return
                     (count($i/tan:l) * count($i/tan:m)))"
                  />
               </xsl:when>
               <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="ana-certs" select="
            for $i in $anas-to-merge
            return
               if ($i/@cert) then
                  number($i/@cert)
               else
                  1"/>
      <xsl:variable name="lms-itemized" as="element()*">
         <xsl:apply-templates select="$anas-to-merge" mode="tan:itemize-lms">
            <xsl:with-param name="ana-cert-sum" select="sum($ana-certs)" tunnel="yes"/>
            <xsl:with-param name="context-tok-count" select="sum($ana-tok-counts)"/>
            <xsl:with-param name="tok-val" select="$regard-only-those-toks-that-have-what-vals"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="lms-grouped" as="element()*">
         <xsl:for-each-group select="$lms-itemized" group-by="tan:l">
            <xsl:variable name="this-lm-cert" select="
                  sum(for $i in current-group()
                  return
                     number($i/@cert))"/>
            <xsl:variable name="this-l-group-count" select="count(current-group())"/>
            <lm>
               <xsl:if
                  test="($this-l-group-count lt count($lms-itemized)) and $this-lm-cert lt 0.9999">
                  <xsl:attribute name="cert" select="$this-lm-cert"/>
               </xsl:if>
               <xsl:copy-of select="current-group()[1]/tan:l"/>
               <xsl:for-each-group select="current-group()" group-by="tan:m">
                  <xsl:variable name="this-m-cert" select="
                        sum(for $i in current-group()
                        return
                           number($i/@cert))"/>
                  <xsl:variable name="this-m-group-count" select="count(current-group())"/>
                  <m>
                     <xsl:if test="$this-m-group-count lt $this-l-group-count">
                        <xsl:attribute name="cert" select="$this-m-cert div $this-lm-cert"/>
                     </xsl:if>
                     <xsl:value-of select="current-grouping-key()"/>
                  </m>
               </xsl:for-each-group>
            </lm>
         </xsl:for-each-group>
      </xsl:variable>
      <ana tok-pop="{sum($ana-tok-counts)}">
         <xsl:copy-of
            select="tan:distinct-items($anas-to-merge/tan:tok[@val = $regard-only-those-toks-that-have-what-vals])"/>
         <xsl:for-each select="$lms-grouped">
            <xsl:sort
               select="
               if (@cert) then
               number(@cert)
               else
               1"
               order="descending"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:l"/>
               <xsl:for-each select="tan:m">
                  <xsl:sort select="
                        if (@cert) then
                           number(@cert)
                        else
                           1" order="descending"/>
                  <xsl:copy-of select="."/>
               </xsl:for-each>
            </xsl:copy>
         </xsl:for-each>
      </ana>
   </xsl:function>
   
   <xsl:mode name="tan:itemize-lms" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:ana" mode="tan:itemize-lms">
      <xsl:param name="ana-cert-sum" as="xs:double?"/>
      <xsl:param name="context-tok-count" as="xs:integer"/>
      <xsl:param name="tok-val" as="xs:string*"/>
      <xsl:variable name="toks-of-interest" select="tan:tok[@val = $tok-val]"/>
      <xsl:variable name="this-tok-count" as="xs:integer">
         <xsl:choose>
            <xsl:when test="exists(@tok-pop)">
               <xsl:value-of select="@tok-pop"/>
            </xsl:when>
            <xsl:when test="exists($toks-of-interest)">
               <xsl:value-of select="count($toks-of-interest)"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:apply-templates select="tan:lm" mode="#current">
         <xsl:with-param name="ana-cert" tunnel="yes"
            select="$this-tok-count div $context-tok-count"/>
         <!--<xsl:with-param name="lm-count" tunnel="yes" select="$this-lm-combo-count"/>-->
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:l" mode="tan:itemize-lms">
      <xsl:param name="ana-cert" as="xs:double" tunnel="yes"/>
      <!--<xsl:param name="lm-count" as="xs:integer" tunnel="yes"/>-->
      <xsl:variable name="this-l" select="."/>
      <xsl:variable name="this-lm-cert" select="number((../@cert, 1)[1])"/>
      <xsl:variable name="this-l-cert" select="number((@cert, 1)[1])"/>
      <!--<xsl:variable name="this-l-pop" select="count(../tan:l)"/>-->
      <xsl:variable name="sibling-ms" select="following-sibling::tan:m"/>
      <!--<xsl:variable name="this-m-pop" select="count($sibling-ms)"/>-->
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode itemize-lms, for: ', ."/>
         <xsl:message select="'ana certainty: ', $ana-cert"/>
         <xsl:message select="'lm certainty: ', $this-lm-cert"/>
         <xsl:message select="'this certainty: ', $this-l-cert"/>
         <xsl:message select="'these m certainties: ', $sibling-ms/@cert"/>
      </xsl:if>
      <xsl:for-each select="$sibling-ms">
         <xsl:variable name="this-m-cert" select="number((@cert, 1)[1])"/>
         <xsl:variable name="this-itemized-lm-cert"
            select="($ana-cert * $this-lm-cert * $this-l-cert * $this-m-cert)"/>
         <lm>
            <xsl:if test="$this-itemized-lm-cert lt 0.9999">
               <xsl:attribute name="cert" select="$this-itemized-lm-cert"/>
            </xsl:if>
            <l>
               <xsl:value-of select="$this-l"/>
            </l>
            <m>
               <xsl:copy-of select="@* except @cert"/>
               <xsl:value-of select="."/>
            </m>
         </lm>
      </xsl:for-each>
   </xsl:template>
   
   
   <xsl:function name="tan:lang-code" as="xs:string*" visibility="public">
      <!-- Input: the name of a language -->
      <!-- Output: the 3-letter code for the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <xsl:param name="lang-name" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$tan:iso-639-3/tan:iso-639-3/tan:l[@name = $lang-name]/@id"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-name) gt 0)">
            <xsl:value-of
               select="
               for $i in $tan:iso-639-3/tan:iso-639-3/tan:l[matches(@name, $lang-name, 'i')]
               return
               string($i/@id)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:lang-name" as="xs:string*" visibility="public">
      <!-- Input: the code of a language -->
      <!-- Output: the name of the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <xsl:param name="lang-code" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$tan:iso-639-3/tan:iso-639-3/tan:l[@id = $lang-code]/@name"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-code) gt 0)">
            <xsl:value-of
               select="
               for $i in $tan:iso-639-3/tan:iso-639-3/tan:l[matches(@id, $lang-code, 'i')]
               return
               string($i/@name)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:lang-catalog" as="document-node()*" visibility="public">
      <!-- Input: language codes -->
      <!-- Output: the catalogs for those languages -->
      <xsl:param name="lang-codes" as="xs:string*"/>
      <xsl:variable name="lang-codes-rev" select="
            if ((count($lang-codes) lt 1) or $lang-codes = '*') then
               '*'
            else
               $lang-codes"/>
      <xsl:for-each select="$lang-codes-rev">
         <xsl:variable name="this-lang-code" select="."/>
         <xsl:variable name="these-catalog-uris" select="
               if ($this-lang-code = '*') then
                  (for $i in $languages-supported
                  return
                     $tan:lang-catalog-map($i))
               else
                  $tan:lang-catalog-map($this-lang-code)"/>
         <xsl:if test="not(exists($these-catalog-uris))">
            <xsl:message select="'No catalogs defined for', $this-lang-code"/>
         </xsl:if>
         <xsl:for-each select="$these-catalog-uris">
            <xsl:variable name="this-uri" select="."/>
            <xsl:choose>
               <xsl:when test="doc-available($this-uri)">
                  <xsl:sequence select="doc($this-uri)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:message select="'Language catalog not available at ', $this-uri"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:variable name="languages-supported" select="map:keys($tan:lang-catalog-map)"/>
   
   <!-- LANGUAGE-SPECIFIC -->
   
   <!-- Greek -->
   
   <xsl:variable name="tan:grc-tokens-without-accents" select="doc('grc-tokens-without-accents.xml')/*/*"/>
   
   <xsl:function name="tan:greek-graves-to-acutes" as="xs:string?" visibility="public">
      <!-- Input: text with Greek -->
      <!-- Output: the same, but with grave accents changed to acutes -->
      <xsl:param name="greek-to-change" as="xs:string?"/>
      <xsl:variable name="this-text-nfkd" select="normalize-unicode($greek-to-change, 'nfkd')"/>
      <xsl:variable name="this-text-fixed" select="replace($this-text-nfkd, '&#x300;', '&#x301;')"/>
      <xsl:sequence select="normalize-unicode($this-text-fixed)"/>
   </xsl:function>
   
   <!-- Syriac -->
   
   <xsl:function name="tan:syriac-marks-to-word-end" as="xs:string?" visibility="public">
      <!-- Input: a string -->
      <!-- Output: the string with Syriac marks placed at the end, in codepoint order -->
      <!-- This function was written to assist in comparing Syriac words that match. Which letter a 
         particular dot is placed should not matter, in most cases. -->
      <xsl:param name="input-syriac-text" as="xs:string?"/>
      <xsl:variable name="output-parts" as="xs:string*">
         <xsl:analyze-string select="$input-syriac-text" regex="[\p{{L}}\p{{M}}]+">
            <xsl:matching-substring>
               <xsl:variable name="these-marks" select="replace(., '\p{L}+', '')"/>
               <xsl:variable name="these-mark-codepoints-sorted" select="sort(string-to-codepoints($these-marks))"/>
               <xsl:variable name="these-letters" select="replace(., '\p{M}+', '')"/>
               <xsl:value-of select="$these-letters"/>
               <xsl:value-of select="codepoints-to-string($these-mark-codepoints-sorted)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:value-of select="string-join($output-parts)"/>
   </xsl:function>
   
   
   
   


</xsl:stylesheet>
