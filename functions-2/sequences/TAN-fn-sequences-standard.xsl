<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library sequence functions. -->
   
   <xsl:function name="tan:duplicate-items" as="item()*" visibility="public">
      <!-- Input: any sequence of items -->
      <!-- Output: those items that appear in the sequence more than once -->
      <!-- This function parallels the standard fn:distinct-values() -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:for-each-group select="$sequence" group-by=".">
         <xsl:if test="count(current-group()) gt 1">
            <xsl:sequence select="current-group()"/>
         </xsl:if>
      </xsl:for-each-group> 
   </xsl:function>
   
   <xsl:function name="tan:duplicate-values" as="item()*" visibility="public">
      <!-- synonym for tan:duplicate-items() -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:sequence select="tan:duplicate-items($sequence)"/>
   </xsl:function>
   
   <xsl:function name="tan:distinct-items" as="item()*" visibility="public">
      <!-- Input: any sequence of items -->
      <!-- Output: Those items that are not deeply equal to any other item in the sequence -->
      <!-- This function is parallel to distinct-values(), but handles non-string input -->
      <xsl:param name="items" as="item()*"/>
      <xsl:sequence select="$items[1]"/>
      <xsl:for-each select="$items[position() gt 1]">
         <xsl:variable name="this-item" select="."/>
         <xsl:if test="
               not(some $i in 1 to position()
                  satisfies deep-equal($this-item, $items[$i]))">
            <xsl:sequence select="."/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:collate-sequences" as="xs:string*" visibility="public">
      <!-- Input: a sequence of elements, each with a sequence of child elements -->
      <!-- Output: a series of strings that is a collation of the text sequences of the input -->
      <!-- Example: 
         Given input:
         <a><t>apple</t><t>banana</t><t>carrot</t></a> 
         <b><t>apple</t><t>carrot</t><t>dessert</t></b> 
         <c><t>apple</t><t>dessert</t></c>
         Output will be:
         ('apple', 'banana', 'carrot', 'dessert')
      -->
      <xsl:param name="elements-with-elements" as="element()*"/>
      <!-- Start with the element that has the greatest number of elements; that will be the grid into which the other sequences will be fit -->
      <xsl:variable name="input-sorted" as="element()*">
         <xsl:for-each select="$elements-with-elements">
            <xsl:sort select="count(*)" order="descending"/>
            <xsl:choose>
               <xsl:when test="count(*) lt 1">
                  <xsl:message>Input elements without elements will be ignored</xsl:message>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="first-sequence" as="xs:string*">
         <xsl:for-each select="$input-sorted[1]/*">
            <xsl:value-of select="."/>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:collate-sequences()'"/>
         <xsl:message select="'input sorted: ', $input-sorted"/>
         <xsl:message select="'first sequence: ', $first-sequence"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="count($input-sorted) lt 2">
            <!--Function called with fewer than two sequences-->
            <xsl:copy-of select="$first-sequence"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:collate-sequence-loop($input-sorted[position() gt 1], $first-sequence)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:collate-sequence-loop" as="xs:string*" visibility="private">
      <!-- This companion function to tan:collate-sequences() takes a pair of sequences and merges them. -->
      <xsl:param name="elements-with-elements" as="element()*"/>
      <xsl:param name="results-so-far" as="xs:string*"/>
      <xsl:choose>
         <xsl:when test="count($elements-with-elements) lt 1">
            <xsl:copy-of select="$results-so-far"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-sequence" as="xs:string*">
               <xsl:for-each select="$elements-with-elements[1]/*">
                  <xsl:value-of select="."/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="this-collation"
               select="tan:collate-pair-of-sequences($results-so-far, $next-sequence)"/>
            <xsl:copy-of
               select="tan:collate-sequence-loop($elements-with-elements[position() gt 1], $this-collation)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:collate-pair-of-sequences" as="element()*" visibility="public">
      <!-- Input: two sequences of strings -->
      <!-- Output: an element sequence that collates the two sequences as a single sequence, attempting to 
         preserve the longest common subsequence. -->
      <!-- This function has been written for two different scenarios: 
        1. @n values in two sets of <div>s that must be collated;
        2. pre-processing two long strings that need to be compared. 
      Although the primary context is two sets of unique string-sequences, one could imagine situations 
      where one or both input strings have repetition, in which case it is best to retain information about the
      sequence. Hence the output is a sequence of elements, with @p1, @p2, or both signifying the position
      of the original input. Hence the transformation is lossless, and the original input can be reconstructed
      if needed.
      -->
      <xsl:param name="string-sequence-1" as="xs:string*"/>
      <xsl:param name="string-sequence-2" as="xs:string*"/>
      
      <xsl:variable name="string-1-length" select="count($string-sequence-1)"/>
      <xsl:variable name="string-1-prep" as="element()">
         <string-1>
            <xsl:for-each select="$string-sequence-1">
               <item p1="{position()}">
                  <xsl:value-of select="."/>
               </item>
            </xsl:for-each>
         </string-1>
      </xsl:variable>
      <xsl:variable name="string-2-prep" as="element()">
         <string-2>
            <xsl:for-each select="$string-sequence-2">
               <xsl:variable name="this-val" select="."/>
               <xsl:variable name="these-s1-matches" select="$string-1-prep/tan:item[. = $this-val]"/>
               <item p2="{position()}">
                  <xsl:value-of select="."/>
                  <xsl:for-each select="$these-s1-matches/@p1">
                     <p1><xsl:value-of select="."/></p1>
                  </xsl:for-each>
               </item>
            </xsl:for-each>
         </string-2>
      </xsl:variable>
      <xsl:variable name="string-2-sequence-of-p1-integers" as="element()*">
         <xsl:for-each select="$string-2-prep/*">
            <xsl:copy>
               <xsl:copy-of select="*"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="longest-ascending-subsquence" as="element()*"
         select="tan:longest-ascending-subsequence($string-2-sequence-of-p1-integers)"/>
      <xsl:variable name="subsequence-length" select="count($longest-ascending-subsquence)"/>
      <xsl:variable name="string-1-groups" as="element()">
         <string-1>
            <xsl:for-each-group select="$string-1-prep/*"
               group-ending-with="self::*[@p1 = $longest-ascending-subsquence]">
               <group pos="{position()}">
                  <xsl:copy-of select="current-group()"/>
               </group>
            </xsl:for-each-group> 
         </string-1>
      </xsl:variable>
      <xsl:variable name="string-2-groups" as="element()">
         <string-2>
            <!-- The $longest-ascending-subsequence is bound to a sequence of 
               <val pos="[INTEGER]">[INTEGER]</val>s, where @pos represents string 2's sequence
            and the text node represents string 1's. -->
            <xsl:for-each-group select="$string-2-prep/*"
               group-ending-with="
               self::*[some $i in $longest-ascending-subsquence
               satisfies ($i/@pos = @p2 and $i = tan:p1)]">
               <group pos="{position()}">
                  <xsl:copy-of select="current-group()"/>
               </group>
            </xsl:for-each-group> 
         </string-2>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:collate-pair-of-sequences()'"/>
         <xsl:message select="'String 1 prepped (', count($string-1-prep/*),  '): ', string-join($string-1-prep/*/text(), ' ')"/>
         <xsl:message select="'String 2 prepped (', count($string-2-prep/*), '): ', string-join($string-2-prep/*//text(), ' ')"/>
         <xsl:message select="'Longest ascending subsequence (', count($longest-ascending-subsquence), '): ', string-join($longest-ascending-subsquence, ' ')"/>
         <xsl:message select="'String 1 grouped: ', $string-1-groups"/>
         <xsl:message select="'String 2 grouped: ', $string-2-groups"/>
         
      </xsl:if>
      
      <xsl:for-each-group select="$string-1-groups/*, $string-2-groups/*" group-by="@pos">
         <xsl:variable name="s1-last" select="current-group()[1]/*[last()]"/>
         <xsl:variable name="s2-last" select="current-group()[2]/*[last()]"/>
         <xsl:choose>
            <xsl:when test="(count(current-group()) eq 2) and ($s1-last/text() eq $s2-last/text())">
               <xsl:copy-of select="current-group()[1]/* except $s1-last"/>
               <xsl:for-each select="current-group()[2]/* except $s2-last">
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:value-of select="text()"/>
                  </xsl:copy>
               </xsl:for-each>
               <xsl:for-each select="$s1-last">
                  <xsl:copy>
                     <xsl:copy-of select="$s1-last/@*"/>
                     <xsl:copy-of select="$s2-last/@*"/>
                     <xsl:value-of select="."/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each select="current-group()/*">
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:value-of select="text()"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each-group>
   </xsl:function>
   
   
   
   <xsl:function name="tan:most-common-item-count" as="xs:integer?" visibility="public">
      <!-- Input: any sequence of items -->
      <!-- Output: the count of the first item that appears most frequently -->
      <!-- If two or more items appear equally frequently, only the first is returned -->
      <!-- Written to help group <u> elements in tan:collate() -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:for-each-group select="$sequence" group-by=".">
         <xsl:sort select="count(current-group())" order="descending"/>
         <xsl:if test="position() = 1">
            <xsl:sequence select="count(current-group())"/>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>
   
   
   <xsl:function name="tan:normalize-sequence" as="xs:string*" visibility="private">
      <!-- Input: any string representing a sequence; the name of the attribute whence the value, i.e., @ref, @pos, @chars, @n -->
      <!-- Output: the string, normalized and sequenced into items; items that are ranges will have the beginning and end points separated by ' - ' -->
      <!-- Note, this function does not analyze or convert types of numerals, and all help requests are left intact; the function is most effective if numerals have been converted to Arabic ahead of time -->
      <!-- Here we're targeting tan:analyze-elements-with-numeral-attributes() template mode arabic-numerals, prelude to tan:sequence-expand(), tan:normalize-refs() -->
      <xsl:param name="sequence-string" as="xs:string?"/>
      <xsl:param name="attribute-name" as="xs:string"/>
      <xsl:variable name="seq-string-pass-1" select="
            if ($attribute-name = $tan:names-of-attributes-that-are-case-indifferent) then
               lower-case(normalize-space($sequence-string))
            else
               normalize-space($sequence-string)"/>
      <xsl:variable name="seq-string-normalized" as="xs:string?">
         <xsl:if test="string-length($seq-string-pass-1) gt 0">
            <!-- all hyphens are special characters, and adjacent spaces should not be treated as delimiting items -->
            <xsl:value-of select="replace($seq-string-pass-1, ' ?- ?', '-')"/>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="primary-tokenization-pattern" as="xs:string">
         <xsl:choose>
            <xsl:when
               test="$attribute-name = $tan:names-of-attributes-that-may-take-multiple-space-delimited-values"
               > +</xsl:when>
            <xsl:otherwise> *, *</xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:normalize-sequence()'"/>
         <xsl:message select="'sequence string: ', $sequence-string"/>
         <xsl:message select="'attribute name: ', $attribute-name"/>
         <xsl:message select="'normalization pass 1: ', $seq-string-pass-1"/>
         <xsl:message select="'normalization pass 2: ', $seq-string-normalized"/>
         <xsl:message select="'tokenization pattern: ', $primary-tokenization-pattern"/>
      </xsl:if>

      <xsl:for-each select="tokenize($seq-string-normalized, $primary-tokenization-pattern)">
         <xsl:choose>
            <xsl:when test="$attribute-name = ('pos', 'chars', 'm-has-how-many-features')">
               <!-- These are attributes that allow data picker items or sequences, which have keywords "last" etc. -->
               <xsl:choose>
                  <xsl:when test=". = ('all', '*')">
                     <xsl:value-of select="'1 - last'"/>
                  </xsl:when>
                  <xsl:when test="matches(., '^((last|max)(-\d+)?|\d+)-((last|max)(-\d+)?|\d+)$')">
                     <xsl:variable name="these-items" as="xs:string+">
                        <xsl:analyze-string select="." regex="((last|max)(-\d+)?|\d+)">
                           <xsl:matching-substring>
                              <xsl:value-of select="replace(., 'max', 'last')"/>
                           </xsl:matching-substring>
                        </xsl:analyze-string>
                     </xsl:variable>
                     <xsl:value-of select="string-join($these-items, ' - ')"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of select="replace(., '-', ' - ')"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="replace(., '-', ' - ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   
   
   <xsl:function name="tan:analyze-sequence" as="element()" visibility="private">
      <!-- two-parameter version of the fuller function below -->
      <xsl:param name="sequence-string" as="xs:string"/>
      <xsl:param name="name-of-attribute" as="xs:string?"/>
      <xsl:sequence select="tan:analyze-sequence($sequence-string, $name-of-attribute, false())"/>
   </xsl:function>
   <xsl:function name="tan:analyze-sequence" as="element()" visibility="private">
      <!-- three-parameter version of the fuller function below -->
      <xsl:param name="sequence-string" as="xs:string"/>
      <xsl:param name="name-of-attribute" as="xs:string?"/>
      <xsl:param name="expand-ranges" as="xs:boolean"/>
      <xsl:sequence
         select="tan:analyze-sequence($sequence-string, $name-of-attribute, $expand-ranges, true())"
      />
   </xsl:function>
   
   <xsl:function name="tan:analyze-sequence" as="element()" visibility="private">
      <!-- Input: any string representing a sequence; the name of the attribute that held the sequence (default 'ref'); should ranges should be expanded?; are ambiguous numerals roman? -->
      <!-- Output: <analysis> with an expansion of the sequence placed in children elements that have the name of the second parameter (with @attr); those children have @from or @to if part of a range. -->
      <!-- If a sequence has a numerical value no numerals other than Arabic should be used. That means @pos and @chars in their original state, but also if @n, then it needs to have been normalized to Arabic numerals before entering this function -->
      <!-- The exception is @ref, which cannot be accurately converted to Arabic numerals before being studied in the context of a class 1 source -->
      <!-- This function expands only those @refs that are situated within an <adjustments>, which needs to be calculated before being applied to a class 1 source. -->
      <!-- If this function is asked to expand ranges within a @ref sequence, it will do so under the strict assumption that all ranges consist of numerically calculable sibling @ns that share the same mother reference. -->
      <!-- Matt 1 4-7 is ok. These are not: Matt-Mark, Matt 1:3-Matt 2, Matt 1:3-4:7 -->
      <!-- If a request for help is detected, the flag will be removed and @help will be inserted in the appropriate child element. -->
      <!-- If ranges are requested to be expanded, it is expected to apply only to integers, and will not operate on values of 'max' or 'last' -->
      <!-- This function normalizes input numerals and strings. -->
      <xsl:param name="sequence-string" as="xs:string?"/>
      <xsl:param name="name-of-attribute" as="xs:string?"/>
      <xsl:param name="expand-ranges" as="xs:boolean"/>
      <xsl:param name="ambig-is-roman" as="xs:boolean?"/>
      <xsl:variable name="attribute-name"
         select="
            if (string-length($name-of-attribute) lt 1) then
               'ref'
            else
               $name-of-attribute"/>
      <xsl:variable name="is-div-ref" select="$attribute-name = ('ref', 'new')" as="xs:boolean"/>
      <xsl:variable name="string-normalized"
         select="tan:normalize-sequence($sequence-string, $attribute-name)" as="xs:string*"/>
      
      <xsl:variable name="pass-1" as="element()">
         <analysis>
            <xsl:for-each select="$string-normalized">
               <xsl:variable name="this-pos" select="position()"/>
               <xsl:variable name="this-value-or-these-range-components" select="tokenize(., ' - ')"/>
               <xsl:variable name="is-range"
                  select="count($this-value-or-these-range-components) gt 1"/>

               <xsl:for-each select="$this-value-or-these-range-components">
                  <xsl:variable name="this-val-checked" select="tan:help-extracted(.)"/>
                  <xsl:variable name="this-val" select="$this-val-checked/text()"/>
                  <xsl:element name="{$attribute-name}">
                     <xsl:attribute name="attr"/>
                     <xsl:if test="$is-range">
                        <xsl:attribute name="{if (position() = 1) then 'from' else 'to'}"/>
                     </xsl:if>
                     <xsl:copy-of select="$this-val-checked/@help"/>
                     <xsl:choose>
                        <xsl:when test="$is-div-ref">
                           <!-- A reference returns both the full normalized form and the individual @n's parsed. -->
                           <!-- We avoid adding the text value of the ref until after individual <n> values are calculated -->
                           <!-- we exclude from ns the hash, which is used to separate adjoining numbers, e.g., 1#2 representing 1b -->
                           <xsl:variable name="these-ns" select="tokenize(., '[^#\w\?_]+')"/>
                           <xsl:for-each select="$these-ns">
                              <xsl:variable name="this-val-checked" select="tan:help-extracted(.)"/>
                              <xsl:variable name="this-atom-val" select="$this-val-checked/text()"/>
                              <xsl:variable name="this-atom-val-norm" select="tan:string-to-numerals(lower-case($this-atom-val), $ambig-is-roman, false(), ())"/>
                              <n>
                                 <xsl:if test="not($this-atom-val eq $this-atom-val-norm)">
                                    <xsl:attribute name="orig" select="$this-atom-val"/>
                                 </xsl:if>
                                 <xsl:copy-of select="$this-val-checked/@help"/>
                                 <xsl:value-of select="$this-atom-val-norm"/>
                              </n>
                           </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:variable name="this-val-norm" select="tan:string-to-numerals(lower-case($this-val), $ambig-is-roman, false(), ())"/>
                           <xsl:if test="not($this-val eq $this-val-norm)">
                              <xsl:attribute name="orig" select="$this-val"/>
                           </xsl:if>
                           <xsl:value-of select="$this-val-norm"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:element>
               </xsl:for-each>
            </xsl:for-each>
         </analysis>
      </xsl:variable>
      <xsl:variable name="pass-2" as="element()">
         <xsl:choose>
            <xsl:when test="$is-div-ref">
               <analysis>
                  <xsl:copy-of select="tan:analyze-ref-loop($pass-1/*, (), ())"/>
               </analysis>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$pass-1"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:analyze-sequence()'"/>
         <xsl:message select="'sequence string: ', $sequence-string"/>
         <xsl:message select="'name of attribute: ', $name-of-attribute"/>
         <xsl:message select="'expand ranges? ', $expand-ranges"/>
         <xsl:message select="'ambig is roman? ', $ambig-is-roman"/>
         <xsl:message select="'string normalized: ', $string-normalized"/>
         <xsl:message select="'pass 1: ', $pass-1"/>
         <xsl:message select="'pass 2: ', $pass-2"/>
      </xsl:if>
      
      <xsl:apply-templates select="$pass-2" mode="tan:check-and-expand-ranges">
         <xsl:with-param name="ambig-is-roman" select="$ambig-is-roman" tunnel="yes"/>
         <xsl:with-param name="expand-ranges" select="$expand-ranges" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:mode name="tan:check-and-expand-ranges" on-no-match="shallow-copy"/>

   <xsl:template match="*[@from][text()]" mode="tan:check-and-expand-ranges">
      <xsl:param name="expand-ranges" tunnel="yes" as="xs:boolean"/>
      <xsl:variable name="this-to" select="following-sibling::*[1][@to]"/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="from-and-to-are-integers" select="text() castable as xs:integer and $this-to/text() castable as xs:integer"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on template mode check-and-expand-ranges for: ', ."/>
         <xsl:message select="'try to expand ranges? ', $expand-ranges"/>
         <xsl:message select="'this to: ', $this-to"/>
      </xsl:if>
      
      <xsl:copy-of select="."/>
      <xsl:choose>
         <xsl:when test="$expand-ranges and $from-and-to-are-integers">
            <xsl:variable name="from-int" select="xs:integer(.)"/>
            <xsl:variable name="to-int" select="xs:integer($this-to)"/>
            <xsl:variable name="this-sequence-expanded"
               select="tan:expand-numerical-sequence((. || ' - ' || $this-to), max(($from-int, $to-int)))"/>
            <xsl:variable name="sequence-errors" select="tan:sequence-error($this-sequence-expanded)"/>
            <xsl:copy-of select="$sequence-errors"/>
            <xsl:for-each select="$this-sequence-expanded[position() gt 1 and position() lt last()]">
               <xsl:element name="{$this-element-name}">
                  <xsl:value-of select="."/>
               </xsl:element>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="$expand-ranges">
            <xsl:copy-of select="tan:error('seq05')"/>
         </xsl:when>
         <xsl:when test="$from-and-to-are-integers">
            <xsl:if test="xs:integer($this-to) le xs:integer(.)">
               <xsl:copy-of select="tan:error('seq03')"/>
            </xsl:if>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tan:ref[@from][tan:n]" priority="1" mode="tan:check-and-expand-ranges">
      <xsl:param name="ambig-is-roman" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="expand-ranges" tunnel="yes" as="xs:boolean"/>
      <xsl:variable name="this-from" select="."/>
      <xsl:variable name="this-last-n" select="tan:n[last()]"/>
      <xsl:variable name="these-preceding-ns" select="tan:n except $this-last-n"/>
      <xsl:variable name="this-to" select="following-sibling::*[1][@to]"/>
      <xsl:variable name="this-to-last-n" select="$this-to/tan:n[last()]"/>
      <xsl:variable name="these-to-preceding-ns" select="$this-to/(tan:n except $this-to-last-n)"/>
      <xsl:variable name="element-name" select="name(.)"/>
      <xsl:variable name="first-value"
         select="tan:string-to-numerals(lower-case($this-last-n), $ambig-is-roman, false(), ())"/>
      <xsl:variable name="last-value"
         select="tan:string-to-numerals(lower-case($this-to-last-n), $ambig-is-roman, false(), ())"/>
      <xsl:variable name="first-is-arabic" select="$first-value castable as xs:integer"/>
      <xsl:variable name="last-is-arabic" select="$last-value castable as xs:integer"/>
      <xsl:variable name="first-is-compound" select="matches($first-value, '^\d+#\d+$')"/>
      <xsl:variable name="last-is-compound" select="matches($last-value, '^\d+#\d+$')"/>
      <xsl:variable name="first-is-number" select="$first-is-arabic or $first-is-compound"/>
      <xsl:variable name="last-is-number" select="$last-is-arabic or $last-is-compound"/>
      <xsl:variable name="last-value-as-int"
         select="
            if ($last-is-arabic) then
               xs:integer($last-value)
            else
               xs:integer(tokenize($last-value, '\D+')[last()])"
         as="xs:integer?"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of
            select="string-join(($these-preceding-ns, $first-value), $tan:separator-hierarchy)"/>
         <xsl:copy-of select="$these-preceding-ns"/>
         <n>
            <xsl:value-of select="$first-value"/>
         </n>
      </xsl:copy>
      <xsl:choose>
         <xsl:when test="not($expand-ranges)"/>
         <xsl:when test="not($first-is-number) and not($last-is-number)">
            <xsl:copy-of
               select="tan:error('seq05', ('neither ' || $this-last-n || ' nor ' || $this-to-last-n || ' are numerals'))"
            />
         </xsl:when>
         <xsl:when test="not($first-is-number)">
            <xsl:copy-of select="tan:error('seq05', ($this-last-n || ' is not a numeral'))"/>
         </xsl:when>
         <xsl:when test="not($last-is-number)">
            <xsl:copy-of select="tan:error('seq05', ($this-to-last-n || ' is not a numeral'))"/>
         </xsl:when>
         <xsl:when test="$first-is-compound or $last-is-compound">
            <xsl:variable name="first-values"
               select="
                  for $i in tokenize($first-value, '#')
                  return
                     xs:integer($i)"
            />
            <xsl:variable name="last-values"
               select="
                  for $i in tokenize($last-value, '#')
                  return
                     xs:integer($i)"
            />
            <xsl:choose>
               <xsl:when test="$first-is-arabic or $last-is-arabic">
                  <xsl:copy-of select="tan:error('seq05', 'A reference range cannot be calculated between a digit and a compound digit.')"/>
               </xsl:when>
               <xsl:when test="$first-values[1] ne $last-values[1]">
                  <xsl:copy-of select="tan:error('seq05', 'A reference range cannot be calculated between compound digits that do not begin identically.')"/>
               </xsl:when>
               <xsl:when test="$first-values[last()] ge $last-values[last()]">
                  <xsl:copy-of select="tan:error('seq05', 'A reference range cannot be calculated from a smaller compound digit to a larger one.')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:for-each select="$first-values[last()] + 1 to $last-values[last()] - 1">
                     <xsl:variable name="this-new-value"
                        select="
                           string-join((for $i in $first-values[position() lt last()]
                           return
                              xs:string($i), xs:string(.)), '#')"
                     />
                     <ref>
                        <xsl:value-of
                           select="string-join(($these-preceding-ns, $this-new-value), $tan:separator-hierarchy)"/>
                        <xsl:copy-of select="$these-preceding-ns"/>
                        <n>
                           <xsl:value-of select="$this-new-value"/>
                        </n>
                     </ref>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when
            test="
               (count($these-preceding-ns) ne count($these-to-preceding-ns))
               or (some $i in (1 to max((count($these-preceding-ns), count($these-to-preceding-ns))))
                  satisfies ($these-preceding-ns[$i] ne $these-to-preceding-ns[$i]))">
            <xsl:copy-of
               select="tan:error('seq05', (string-join($these-preceding-ns, $tan:separator-hierarchy) || ' and ' || string-join($these-to-preceding-ns, $tan:separator-hierarchy) || ' should be identical'))"
            />
         </xsl:when>
         <xsl:when test="xs:integer($first-value) ge xs:integer($last-value)">
            <xsl:copy-of
               select="tan:error('seq05', ($this-last-n || ' should be less than ' || $this-to-last-n))"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:for-each select="xs:integer($first-value) + 1 to xs:integer($last-value) - 1">
               <ref>
                  <xsl:value-of
                     select="string-join(($these-preceding-ns, xs:string(.)), $tan:separator-hierarchy)"/>
                  <xsl:copy-of select="$these-preceding-ns"/>
                  <n>
                     <xsl:value-of select="."/>
                  </n>
               </ref>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:function name="tan:analyze-ref-loop" as="element()*" visibility="private">
      <!-- Input: elements from tan:analyze-sequence() -->
      <!-- Output: each <ref> is supplied with any missing, and calculable, <n>s -->
      <!-- This function takes a string such as "1.3-5, 8, 4.2-3" and converts it to "1.3, 1.5, 1.8, 4.2, 4.3" -->
      <!-- If the function moves from one <ref> to one with greater than or equal number of <n>s, the new one becomes the context; otherwise, the new <ref> attracts from the context any missing <n>s at its head -->
      <xsl:param name="elements-to-process" as="element()*"/>
      <xsl:param name="number-of-ns-in-last-item-processed" as="xs:integer?"/>
      <xsl:param name="current-contextual-ref" as="element()?"/>
      <xsl:variable name="this-element-to-process" select="$elements-to-process[1]"/>
      <xsl:variable name="number-of-ns" select="count($this-element-to-process/tan:n)"/>
      <xsl:variable name="number-of-contextual-ns" select="count($current-contextual-ref/tan:n)"/>
      <xsl:choose>
         <xsl:when test="not(exists($this-element-to-process))"/>
         <xsl:otherwise>
            <xsl:choose>
               <xsl:when
                  test="$number-of-ns gt $number-of-ns-in-last-item-processed or $number-of-ns ge $number-of-contextual-ns or not(exists($current-contextual-ref))">
                  <!-- e.g., ... 1, *2 1* ... -->
                  <xsl:element name="{name($this-element-to-process)}">
                     <xsl:copy-of select="$this-element-to-process/@*"/>
                     <xsl:value-of
                        select="string-join($this-element-to-process/*, $tan:separator-hierarchy)"/>
                     <xsl:copy-of select="$this-element-to-process/*"/>
                  </xsl:element>
                  <xsl:copy-of
                     select="tan:analyze-ref-loop($elements-to-process[position() gt 1], $number-of-ns, $this-element-to-process)"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="current-context-last-digit" select="$current-contextual-ref/*[last()]"/>
                  <xsl:variable name="this-last-digit" select="$this-element-to-process/*[last()]"/>
                  <!-- Fix cases such as 1a - d, where 1d is implied for the last digit -->
                  <xsl:variable name="adjust-last-digit"
                     select="
                        contains($current-context-last-digit, '#')
                        and not(contains($this-last-digit, '#'))
                        and (
                           matches($current-context-last-digit/@orig, '^\d') ne matches($this-last-digit/@orig, '^\d')
                        )"
                  />
                  <xsl:variable name="new-children" as="element()*">
                     <xsl:sequence
                        select="$current-contextual-ref/*[position() le ($number-of-contextual-ns - $number-of-ns)]"
                     />
                     <xsl:choose>
                        <xsl:when test="$adjust-last-digit">
                           <xsl:sequence select="$this-element-to-process/* except $this-last-digit"/>
                           <n>
                              <xsl:copy-of select="$this-last-digit/@*"/>
                              <xsl:value-of select="tokenize($current-context-last-digit, '#')[1] || '#' || $this-last-digit"/>
                           </n>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:sequence select="$this-element-to-process/*"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:variable>
                  <xsl:element name="{name($this-element-to-process)}">
                     <xsl:copy-of select="$this-element-to-process/@*"/>
                     <xsl:value-of select="string-join($new-children, $tan:separator-hierarchy)"/>
                     <xsl:copy-of select="$new-children"/>
                  </xsl:element>
                  <xsl:copy-of
                     select="tan:analyze-ref-loop($elements-to-process[position() gt 1], $number-of-ns, $current-contextual-ref)"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:expand-pos-or-chars" as="xs:integer*" visibility="private">
      <!-- Input: any elements that are <pos> or <chars>; an integer value for 'max' -->
      <!-- Output: the elements converted to integers they represent -->
      <!-- Because the results are normally positive integers, the following should be treated as error codes:
            0 = value that falls below 1;
            -1 = value that cannot be converted to an integer;
            -2 = ranges that call for negative steps, e.g., '4 - 2'. -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:param name="max" as="xs:integer?"/>
      <xsl:variable name="elements-prepped" as="element()">
         <elements>
            <xsl:copy-of select="$elements"/>
         </elements>
      </xsl:variable>
      <xsl:for-each-group select="$elements-prepped/*"
         group-by="count((self::*, preceding-sibling::*)[not(@to)])">
         <xsl:variable name="elements-to-analyze" select="current-group()"/>
         <xsl:variable name="ints-pass1" as="xs:integer*">
            <xsl:for-each select="$elements-to-analyze">
               <xsl:variable name="pass1a" as="xs:integer*">
                  <xsl:analyze-string select="." regex="(max|all|last)-?">
                     <xsl:matching-substring>
                        <xsl:copy-of select="$max"/>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:choose>
                           <xsl:when test=". castable as xs:integer">
                              <xsl:copy-of select="xs:integer(.)"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of select="-1"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:variable>
               <xsl:copy-of select="
                     if ($pass1a[2] = -1) then
                        -1
                     else
                        $pass1a[1] - ($pass1a[2], 0)[1]"/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:choose>
            <xsl:when
               test="
               some $i in $ints-pass1
               satisfies $i = -1">
               <xsl:sequence select="-1"/>
            </xsl:when>
            <xsl:when
               test="
               some $i in $ints-pass1
               satisfies $i lt 1">
               <xsl:sequence select="0"/>
            </xsl:when>
            <xsl:when test="count($ints-pass1) lt 2">
               <xsl:sequence select="$ints-pass1"/>
            </xsl:when>
            <xsl:when test="$ints-pass1[2] lt $ints-pass1[1]">
               <xsl:sequence select="-2"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$ints-pass1[1] to $ints-pass1[2]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each-group>
   </xsl:function>
   
   <xsl:function name="tan:expand-numerical-sequence" as="xs:integer*" visibility="public">
      <!-- Input: a string representing a TAN selector (used by @pos, @chars), and an integer defining the value of 'last' -->
      <!-- Output: a sequence of numbers representing the positions selected, unsorted, and retaining duplicate values.
            Example: ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
            Errors will be flagged as follows:
            0 = value that falls below 1;
            -1 = value that surpasses the value of $max;
            -2 = ranges that call for negative steps, e.g., '4 - 2'. -->
      <!-- This function assumes that all numerals are Arabic. -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <!-- first normalize syntax -->
      <xsl:variable name="pass-1" select="tan:normalize-sequence($selector, 'pos')"/>
      <xsl:variable name="pass-2" as="xs:string*">
         <xsl:for-each select="$pass-1">
            <xsl:variable name="this-last-norm" as="xs:string+">
               <xsl:analyze-string select="." regex="last-?(\d*)">
                  <xsl:matching-substring>
                     <xsl:variable name="number-to-subtract"
                        select="
                        if (string-length(regex-group(1)) gt 0) then
                        number(regex-group(1))
                        else
                        0"
                     />
                     <xsl:value-of select="string(($max - $number-to-subtract))"/>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
            <xsl:value-of select="string-join($this-last-norm, '')"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$pass-2">
         <xsl:variable name="range"
            select="
            for $i in tokenize(., ' - ')
            return
            xs:integer($i)"/>
         <xsl:choose>
            <xsl:when test="$range[1] lt 1 or $range[2] lt 1">
               <xsl:sequence select="0"/>
            </xsl:when>
            <xsl:when test="$range[1] gt $max or $range[2] gt $max">
               <xsl:sequence select="-1"/>
            </xsl:when>
            <xsl:when test="$range[1] gt $range[2]">
               <xsl:sequence select="-2"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$range[1] to $range[last()]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:sequence-error" as="element()*" visibility="private">
      <xsl:param name="results-of-sequence-expand" as="xs:integer*"/>
      <xsl:copy-of select="tan:sequence-error($results-of-sequence-expand, ())"/>
   </xsl:function>
   <xsl:function name="tan:sequence-error" as="element()*" visibility="private">
      <!-- Input: any results of the function tan:sequence-expand() -->
      <!-- Output: error nodes, if any -->
      <xsl:param name="results-of-sequence-expand" as="xs:integer*"/>
      <xsl:param name="message" as="xs:string?"/>
      <xsl:for-each select="$results-of-sequence-expand[. lt 1]">
         <xsl:if test=". = 0">
            <xsl:copy-of select="tan:error('seq01', $message)"/>
         </xsl:if>
         <xsl:if test=". = -1">
            <xsl:copy-of select="tan:error('seq02', $message)"/>
         </xsl:if>
         <xsl:if test=". = -2">
            <xsl:copy-of select="tan:error('seq03', $message)"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:sequence-collapse" as="xs:string?" visibility="public">
      <!-- Input: a sequence of integers -->
      <!-- Output: a string that puts them in a TAN-like compact string -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:variable name="pass1" as="xs:integer*">
         <xsl:for-each select="$integers">
            <xsl:sort/>
            <xsl:copy-of select="."/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="pass2" as="element()*">
         <xsl:for-each select="$pass1">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="prev" select="($pass1[$pos - 1], 0)[1]"/>
            <item val="{.}" diff-with-prev="{. - $prev}"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="pass3" as="xs:string*">
         <xsl:for-each-group select="$pass2"
            group-starting-with="*[xs:integer(@diff-with-prev) gt 1]">
            <xsl:choose>
               <xsl:when test="count(current-group()) gt 1">
                  <xsl:value-of
                     select="current-group()[1]/@val || '-' || current-group()[last()]/@val"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="current-group()/@val"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:value-of select="string-join($pass3, ', ')"/>
   </xsl:function>
   
   
   
   <xsl:function name="tan:longest-ascending-subsequence" as="element()*" visibility="public">
      <!-- Input: a sequence of items. Each item is either an integer or a sequence of integers (via child elements) -->
      <!-- Output: a sequence of elements. Each one has in its text node an integer greater than the preceding element's text node. 
         Each output element has a @pos with an integer identifying the position of the input item that has been chosen (to handle 
         repetitions in the input) -->
      <!-- Although this function claims by its name to find the longest subsequence, in the interests of efficiency, it applies 
         the so-called Patience method of finding the string, which may return only a very long string, not the longest possible string. 
         Such an approach allows the number of operations to be directly proportionate to the number of input values (backtracking would 
         be computationally intensive on long sequences). The routine does "remember" gaps. If adding a number to the sequence would 
         require a jump, the sequence is created, but a copy of the pre-gapped sequence is memoized, in case it is later discovered that
         the pre-gapped sequence is better. 
      -->
      <!-- The input allows a sequence of elements, along with integers, because this function has been written to support 
         tan:collate-pairs-of-sequences(), which requires choice options. That is, you may have a situation
         where you are comparing two sequences, either of which may have values that repeat, e.g., (a, b, c, b, d) and 
         (c, b, d). The first sequence is converted (1, 2, 3, 4, 5). In finding a corresponding sequence of integers
         for the second set, b must be allowed to be either 2 or 4, i.e., the array [3, [2, 4], 5]. Both items of input would ideally 
         be expressed as arrays of integers, but this function serves an XSLT 2.0 library (where arrays are not recognized), and 
         arrays are not as easy to construct and extract in XSLT 3.0 as maps are. -->
      <xsl:param name="integer-sequence" as="item()*"/>
      <xsl:variable name="sequence-count" select="count($integer-sequence)"/>
      <xsl:variable name="first-item" select="$integer-sequence[1]"/>

      <xsl:variable name="subsequences" as="element()*">
         <xsl:iterate select="$integer-sequence">
            <xsl:param name="subsequences-so-far" as="element()*"/>
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:variable name="these-ints" as="xs:integer*">
               <xsl:choose>
                  <!-- If the item's children are castable as a sequence of integers, do so-->
                  <xsl:when test="
                        every $i in *
                           satisfies $i castable as xs:integer">
                     <xsl:sequence select="
                           for $i in *
                           return
                              xs:integer($i)"/>
                  </xsl:when>
                  <!-- If the item is castable as a single integer, do so -->
                  <xsl:when test=". castable as xs:integer">
                     <xsl:sequence select="xs:integer(.)"/>
                  </xsl:when>
                  <!-- Otherwise we don't know what kind of input is being given, and the item is skipped. -->
                  <xsl:otherwise>
                     <xsl:message
                        select="'Cannot interpret the following as an integer or sequence of integers: ' || ."
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <!-- Look at the sequences so far and find those whose first (i.e., reversed last) value is less than
            the current value -->
            <xsl:variable name="eligible-subsequences"
               select="$subsequences-so-far[xs:integer(tan:val[1]) lt max($these-ints)][not(@before) or (xs:integer(@before) gt min($these-ints))]"/>
            <xsl:variable name="new-subsequences" as="element()*">
               <xsl:for-each select="$these-ints">
                  <!-- Iterate over each of the integers in the current item and build new sequences out of the
                  eligible ones. -->
                  <xsl:variable name="this-int" select="."/>
                  <!-- Find within the eligible subsequences (1) those that are gapped (marked by @before) and the integer 
                     precedes where the gap was, (2) the standard <seq> that -->
                  <xsl:variable name="these-eligible-subsequences"
                     select="$eligible-subsequences[xs:integer(tan:val[1]) lt $this-int][not(@before) 
                     or (xs:integer(@before) gt $this-int)]"/>
                  <xsl:for-each select="$these-eligible-subsequences">
                     <xsl:sort select="count(*)" order="descending"/>
                     <xsl:variable name="this-subsequence-last-int" select="xs:integer(tan:val[1])"/>
                     <!-- Retain as a default only the longest new subsequence -->
                     <xsl:if test="position() eq 1">
                        <xsl:copy>
                           <val pos="{$this-pos}">
                              <xsl:value-of select="$this-int"/>
                           </val>
                           <xsl:copy-of select="*"/>
                        </xsl:copy>
                        <!-- If there's a gap in the sequence, "remember" the sequence before the gap -->
                        <xsl:if test="$this-int gt ($this-subsequence-last-int + 1)">
                           <gap before="{$this-int}">
                              <xsl:copy-of select="*"/>
                           </gap>
                        </xsl:if>
                     </xsl:if>
                  </xsl:for-each>
                  <xsl:if test="not(exists($these-eligible-subsequences))">
                     <!-- If there's no match, let the integer start a new subsequence -->
                     <seq>
                        <val pos="{$this-pos}">
                           <xsl:value-of select="."/>
                        </val>
                     </seq>
                  </xsl:if>
               </xsl:for-each>
               <xsl:copy-of select="$subsequences-so-far except $eligible-subsequences"/>
            </xsl:variable>

            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:longest-ascending-subsequence(), building $subsequences'"/>
               <xsl:message select="'Iteration number: ', $this-pos"/>
               <xsl:message select="'These integers: ', $these-ints"/>
               <xsl:message select="
                  'Eligible subsequences: ',
                  string-join(for $i in $eligible-subsequences
                  return
                  string-join((name($i), name($i/@before), $i/(@before, *)), ' '), '; ')"
               />
               <xsl:message select="
                  'New subsequences: ',
                  string-join(for $i in $new-subsequences
                  return
                  string-join((name($i), name($i/@before), $i/(@before, *)), ' '), '; ')"
               />
            </xsl:if>

            <xsl:if test="position() eq ($sequence-count)">
               <xsl:copy-of select="$new-subsequences"/>
            </xsl:if>
            <xsl:next-iteration>
               <xsl:with-param name="subsequences-so-far" select="$new-subsequences"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>

      <!-- The longest subsequence might not be at the top, so we re-sort, then
      return a reversal of the children (because the subsequence was built in
      reverse). -->
      <xsl:for-each select="$subsequences">
         <xsl:sort select="count(*)" order="descending"/>
         <xsl:if test="position() eq 1">
            <xsl:for-each select="reverse(*)">
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </xsl:if>
      </xsl:for-each>

   </xsl:function>


</xsl:stylesheet>
