<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:saxon="http://saxon.sf.net/"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:file="http://expath.org/ns/file" xmlns:bin="http://expath.org/ns/binary"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
   version="3.0">

   <!-- Are advanced Saxon features available? -->
   <xsl:param name="advanced-saxon-features-available" static="yes"
      select="system-property('xsl:supports-higher-order-functions') eq 'yes'"/>

   <xsl:include href="extra/TAN-function-functions.xsl"/>
   <xsl:include href="extra/TAN-schema-functions.xsl"/>
   <xsl:include href="extra/TAN-search-functions.xsl"/>
   <xsl:include href="extra/TAN-language-functions.xsl"/>
   <xsl:include href="extra/TAN-A-lm-extra-functions.xsl"/>
   <xsl:include href="extra/TAN-output-functions.xsl"/>
   <xsl:include href="../parameters/extra-parameters.xsl"/>

   <!-- Functions that are not central to validating TAN files, but could be helpful in creating, editing, or reusing them -->

   <xsl:key name="get-ana" match="tan:ana" use="tan:tok/@val"/>

   <!-- GLOBAL VARIABLES AND PARAMETERS -->

   <xsl:variable name="doc-history" select="tan:get-doc-history($orig-self)"/>
   <!--<xsl:variable name="doc-filename" select="replace($doc-uri, '.*/([^/]+)$', '$1')"/>-->
   <xsl:variable name="doc-filename" select="tan:cfne(/)"/>
   <xsl:param name="saxon-extension-functions-available" static="yes" as="xs:boolean" select="function-available('saxon:evaluate', 3)"/>
   
   <!-- sources -->
   <!--<xsl:variable name="sources-1st-da" select="tan:get-1st-doc($head/tan:source)"/>
   <xsl:variable name="sources-must-be-adjusted"
      select="exists($head/tan:adjustments/(tan:equate, tan:rename, tan:reassign, tan:skip))"/>
   <xsl:variable name="sources-resolved" as="document-node()*"
      select="tan:resolve-doc($sources-1st-da, $sources-must-be-adjusted, 'src', $source-ids, ($validation-phase = 'verbose'))"/>-->
   
   <!-- annotations (class-1 files pointing to corresponding class-2 files) -->
   <xsl:variable name="annotations-1st-da" select="tan:get-1st-doc($head/tan:annotation)"/>
   <xsl:variable name="annotations-resolved"
      select="tan:resolve-doc($annotations-1st-da, false(), tan:attr('relationship', 'annotation'))"/>
   
   <!-- see-also, context -->
   <xsl:variable name="see-alsos-1st-da" select="tan:get-1st-doc($head/tan:see-also)"/>
   <!--<xsl:variable name="see-alsos-resolved" select="tan:resolve-doc($see-alsos-1st-da, false(), 'see-also', (), ($validation-phase = 'verbose'))"/>-->
   <xsl:variable name="see-alsos-resolved"
      select="tan:resolve-doc($see-alsos-1st-da, false(), tan:attr('relationship', 'see-also'))"/>
   
   <!-- predecessors -->
   <xsl:variable name="predecessors-1st-da" select="tan:get-1st-doc($head/tan:predecessor)"/>
   <!--<xsl:variable name="predecessors-resolved" select="tan:resolve-doc($predecessors-1st-da, false(), 'predecessor', (), ($validation-phase = 'verbose'))"/>-->
   <xsl:variable name="predecessors-resolved" select="tan:resolve-doc($predecessors-1st-da, false(), tan:attr('relationship', 'predecessor'))"/>
   
   <!-- successors -->
   <xsl:variable name="successors-1st-da" select="tan:get-1st-doc($head/tan:successor)"/>
   <!--<xsl:variable name="successors-resolved" select="tan:resolve-doc($successors-1st-da, false(), 'successor', (), ($validation-phase = 'verbose'))"/>-->
   <xsl:variable name="successors-resolved" select="tan:resolve-doc($successors-1st-da, false(), tan:attr('relationship', 'successor'))"/>
   
   <!-- morphologies -->
   <xsl:variable name="morphologies-expanded"
      select="tan:expand-doc($morphologies-resolved, 'terse', false())" as="document-node()*"/>
   
   
   <xsl:variable name="most-common-indentations" as="xs:string*">
      <xsl:for-each-group select="//text()[not(matches(., '\S'))][following-sibling::*]"
         group-by="count(ancestor::*)">
         <xsl:sort select="current-grouping-key()"/>
         <xsl:value-of select="tan:most-common-item(current-group())"/>
      </xsl:for-each-group>
   </xsl:variable>

   <!-- An xpath pattern built into a text node or an attribute value looks like this: {PATTERN} -->
   <xsl:variable name="xpath-pattern" select="'\{[^\}]+?\}'"/>

   <xsl:variable name="namespaces-and-prefixes" as="element()">
      <namespaces>
         <ns prefix="" uri=""/>
         <ns prefix="cp"
            uri="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"/>
         <ns prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>
         <ns prefix="dcmitype" uri="http://purl.org/dc/dcmitype/"/>
         <ns prefix="dcterms" uri="http://purl.org/dc/terms/"/>
         <ns prefix="html" uri="http://www.w3.org/1999/xhtml"/>
         <ns prefix="m" uri="http://schemas.openxmlformats.org/officeDocument/2006/math"/>
         <ns prefix="map" uri="http://www.w3.org/2005/xpath-functions/map"/>
         <ns prefix="mc" uri="http://schemas.openxmlformats.org/markup-compatibility/2006"/>
         <ns prefix="mo" uri="http://schemas.microsoft.com/office/mac/office/2008/main"/>
         <ns prefix="mods" uri="http://www.loc.gov/mods/v3"/>
         <ns prefix="mv" uri="urn:schemas-microsoft-com:mac:vml"/>
         <ns prefix="o" uri="urn:schemas-microsoft-com:office:office"/>
         <ns prefix="r" uri="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
         <ns prefix="rel" uri="http://schemas.openxmlformats.org/package/2006/relationships"/>
         <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
         <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
         <ns prefix="v" uri="urn:schemas-microsoft-com:vml"/>
         <ns prefix="w" uri="http://schemas.openxmlformats.org/wordprocessingml/2006/main"/>
         <ns prefix="w10" uri="urn:schemas-microsoft-com:office:word"/>
         <ns prefix="w14" uri="http://schemas.microsoft.com/office/word/2010/wordml"/>
         <ns prefix="w15" uri="http://schemas.microsoft.com/office/word/2012/wordml"/>
         <ns prefix="wne" uri="http://schemas.microsoft.com/office/word/2006/wordml"/>
         <ns prefix="wp"
            uri="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"/>
         <ns prefix="wp14" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"/>
         <ns prefix="wpc" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"/>
         <ns prefix="wpg" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"/>
         <ns prefix="wpi" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"/>
         <ns prefix="wps" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"/>
         <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
         <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
         <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
         <ns prefix="zs" uri="http://www.loc.gov/zing/srw/"/>
      </namespaces>
   </xsl:variable>


   <!-- Parameters can be easily changed upstream by users who wish to depart from the defaults -->
   <xsl:param name="searches-ignore-accents" select="true()" as="xs:boolean"/>
   <xsl:param name="searches-are-case-sensitive" select="false()" as="xs:boolean"/>
   <xsl:param name="match-flags"
      select="
         if ($searches-are-case-sensitive = true()) then
            ()
         else
            'i'"
      as="xs:string?"/>
   <xsl:param name="searches-suppress-what-text" as="xs:string?" select="'[\p{M}]'"/>

   <!--<xsl:variable name="local-TAN-collection" as="document-node()*"
      select="tan:collection($local-catalog, (), (), ())"/>-->
   <xsl:variable name="local-TAN-collection" as="document-node()*"
      select="collection(concat(resolve-uri('catalog.tan.xml', $doc-uri), '?on-error=warning'))"/>
   <xsl:variable name="local-TAN-voc-collection" select="$local-TAN-collection[name(*) = 'TAN-voc']"/>
   
   <!--<xsl:variable name="applications-collection" as="document-node()*"
      select="collection(concat('../applications/catalog.xml', '?on-error=ignore'))"/>-->
   <xsl:variable name="applications-uri-collection"
      select="uri-collection('../applications/catalog.xml?on-error=ignore')"/>
   <xsl:variable name="applications-collection" as="document-node()*">
      <xsl:for-each select="$applications-uri-collection">
         <xsl:choose>
            <xsl:when test="doc-available(.)">
               <xsl:sequence select="doc(.)"/>
            </xsl:when>
            <xsl:when test="$is-validation"/>
            <xsl:otherwise>
               <xsl:message select="'applications collection has bad entry for ', ."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:variable>

   <xsl:variable name="today-iso" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>

   <!-- FUNCTIONS -->

   <!-- Functions: numerics -->

   <xsl:function name="tan:grc-to-int" as="xs:integer*">
      <!-- Input: Greek letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <xsl:param name="greek-numerals" as="xs:string*"/>
      <xsl:sequence select="tan:letter-to-number($greek-numerals)"/>
   </xsl:function>

   <xsl:function name="tan:syr-to-int" as="xs:integer*">
      <!-- Input: Syriac letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <xsl:param name="syriac-numerals" as="xs:string*"/>
      <xsl:for-each select="$syriac-numerals">
         <xsl:variable name="orig-numeral-seq" as="xs:string*">
            <xsl:analyze-string select="." regex=".">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <!-- The following removes redoubled numerals as often happens in Syriac, to indicate clearly that a character is a numeral not a letter. -->
         <xsl:variable name="duplicates-stripped"
            select="
               for $i in (1 to count($orig-numeral-seq))
               return
                  if ($orig-numeral-seq[$i] = $orig-numeral-seq[$i + 1]) then
                     ()
                  else
                     $orig-numeral-seq[$i]"/>
         <xsl:sequence select="tan:letter-to-number(string-join($duplicates-stripped, ''))"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:int-to-aaa" as="xs:string*">
      <!-- Input: any integers -->
      <!-- Output: the alphabetic representation of those numerals -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:for-each select="$integers">
         <xsl:variable name="this-integer" select="."/>
         <xsl:variable name="this-letter-codepoint" select="(. mod 26) + 96"/>
         <xsl:variable name="this-number-of-letters" select="(. idiv 26) + 1"/>
         <xsl:variable name="these-codepoints"
            select="
               for $i in (1 to $this-number-of-letters)
               return
                  $this-letter-codepoint"/>
         <xsl:value-of select="codepoints-to-string($these-codepoints)"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:int-to-grc" as="xs:string*">
      <!-- Input: any integers -->
      <!-- Output: the integers expressed as lowercase Greek alphabetic numerals, with numeral marker(s) -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:variable name="arabic-numerals" select="'123456789'"/>
      <xsl:variable name="greek-units" select="'αβγδεϛζηθ'"/>
      <xsl:variable name="greek-tens" select="'ικλμνξοπϙ'"/>
      <xsl:variable name="greek-hundreds" select="'ρστυφχψωϡ'"/>
      <xsl:for-each select="$integers">
         <xsl:variable name="this-numeral" select="format-number(., '0')"/>
         <xsl:variable name="these-digits" select="tan:chop-string($this-numeral)"/>
         <xsl:variable name="new-digits-reversed" as="xs:string*">
            <xsl:for-each select="reverse($these-digits)">
               <xsl:variable name="pos" select="position()"/>
               <xsl:choose>
                  <xsl:when test=". = '0'"/>
                  <xsl:when test="$pos mod 3 = 1">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-units)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 2">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-tens)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 0">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-hundreds)"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="prepended-numeral-sign"
            select="
               if (count($these-digits) gt 3) then
                  '͵'
               else
                  ()"/>
         <xsl:if test="count($new-digits-reversed) gt 0">
            <xsl:value-of
               select="concat($prepended-numeral-sign, string-join(reverse($new-digits-reversed), ''), 'ʹ')"
            />
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:dec-to-bin" as="xs:string?">
      <!-- Input: a decimal -->
      <!-- Output: the number in binary, represented as a string -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:sequence select="tan:dec-to-n($in, 2)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:base64-to-dec" as="xs:integer?">
      <!-- Input: a base64 datum -->
      <!-- Output: an integer representing the base-10 value of the input -->
      <xsl:param name="base64" as="xs:base64Binary?"/>
      <xsl:variable name="base64-string" select="xs:string($base64)"/>
      <xsl:copy-of select="tan:n-to-dec($base64-string, 64)"/>
   </xsl:function>
   
   <xsl:function name="tan:base64-to-bin" as="xs:string?">
      <!-- Input: a base64 datum -->
      <!-- Output: a string representing the datum in binary code -->
      <xsl:param name="base64" as="xs:base64Binary?"/>
      <xsl:copy-of select="tan:dec-to-bin(tan:base64-to-dec($base64))"/>
   </xsl:function>

   <xsl:function name="tan:counts-to-lasts" xml:id="f-counts-to-lasts" as="xs:integer*">
      <!-- Input: sequence of numbers representing counts of items. 
         Output: sequence of numbers representing the last position of each item within the total count.
      E.g., (4, 12, 0, 7) - > (4, 16, 16, 23)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of
         select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j])"
      />
   </xsl:function>

   <xsl:function name="tan:lengths-to-positions" as="xs:integer*">
      <!-- Input: sequence of numbers representing legnths of items.  -->
      <!-- Output: sequence of numbers representing the first position of each input item, if the sequence concatenated.
      E.g., (4, 12, 0, 7) - > (1, 5, 17, 17)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of
         select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j]) - $seq[$i] + 1"
      />
   </xsl:function>

   <xsl:function name="tan:product" as="xs:double?">
      <!-- Input: a sequence of numbers -->
      <!-- Output: the product of those numbers -->
      <xsl:param name="numbers" as="item()*"/>
      <xsl:copy-of select="tan:product-loop($numbers[1], subsequence($numbers, 2))"/>
   </xsl:function>
   <xsl:function name="tan:product-loop" as="xs:double?">
      <xsl:param name="product-so-far" as="xs:double?"/>
      <xsl:param name="numbers-to-multiply" as="item()*"/>
      <xsl:choose>
         <xsl:when test="count($numbers-to-multiply) lt 1">
            <xsl:copy-of select="$product-so-far"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:product-loop(($product-so-far * xs:double($numbers-to-multiply[1])), subsequence($numbers-to-multiply, 2))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:number-sort" as="xs:double*">
      <!-- Input: any sequence of items -->
      <!-- Output: the same sequence, sorted with string numerals converted to numbers -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-norm" as="item()*"
         select="
            for $i in $numbers
            return
               if ($i castable as xs:double) then
                  number($i)
               else
                  $i"/>
      <xsl:for-each select="$numbers-norm">
         <xsl:sort/>
         <xsl:copy-of select="."/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:median" as="xs:double?">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the median value -->
      <!-- It is assumed that the input has already been sorted by tan:numbers-sorted() vel sim -->
      <xsl:param name="numbers" as="xs:double*"/>
      <xsl:variable name="number-count" select="count($numbers)"/>
      <xsl:variable name="mid-point" select="$number-count div 2"/>
      <xsl:variable name="mid-point-ceiling" select="ceiling($mid-point)"/>
      <xsl:choose>
         <xsl:when test="$mid-point = $mid-point-ceiling">
            <xsl:copy-of
               select="avg(($numbers[$mid-point-ceiling], $numbers[$mid-point-ceiling - 1]))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="xs:double($numbers[$mid-point-ceiling])"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:outliers" as="xs:anyAtomicType*">
      <!-- Input: any sequence of numbers -->
      <!-- Output: outliers in the sequence -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-sorted" select="tan:number-sort($numbers)" as="xs:anyAtomicType*"/>
      <xsl:variable name="half-point" select="count($numbers) idiv 2"/>
      <xsl:variable name="top-half" select="$numbers-sorted[position() le $half-point]"/>
      <xsl:variable name="bottom-half" select="$numbers-sorted[position() gt $half-point]"/>
      <xsl:variable name="q1" select="tan:median($top-half)"/>
      <xsl:variable name="q2" select="tan:median($numbers)"/>
      <xsl:variable name="q3" select="tan:median($bottom-half)"/>
      <xsl:variable name="interquartile-range" select="$q3 - $q1"/>
      <xsl:variable name="outer-fences" select="$interquartile-range * 3"/>
      <xsl:variable name="top-fence" select="$q1 - $outer-fences"/>
      <xsl:variable name="bottom-fence" select="$q3 + $outer-fences"/>
      <xsl:variable name="top-outliers" select="$top-half[. lt $top-fence]"/>
      <xsl:variable name="bottom-outliers" select="$bottom-half[. gt $bottom-fence]"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:outliers()'"/>
         <xsl:message select="'numbers sorted: ', $numbers-sorted"/>
      </xsl:if>
      
      <xsl:for-each select="$numbers">
         <xsl:variable name="this-number"
            select="
               if (. instance of xs:string) then
                  number(.)
               else
                  xs:double(.)"/>
         <xsl:if test="$this-number = ($top-outliers, $bottom-outliers)">
            <xsl:copy-of select="."/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:no-outliers" as="xs:anyAtomicType*">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the same sequence, without outliers -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="outliers" select="tan:outliers($numbers)"/>
      <xsl:copy-of select="$numbers[not(. = $outliers)]"/>
   </xsl:function>


   <xsl:function name="tan:analyze-stats" as="element()?">
      <!-- Input: a sequence of numbers -->
      <!-- Output: a single <stats> with attributes calculating the count, sum, average, max, min, variance, standard deviation, and then one child <d> per datum with the value of the datum -->
      <xsl:param name="arg" as="xs:anyAtomicType*"/>
      <xsl:variable name="this-avg" select="avg($arg)"/>
      <xsl:variable name="these-deviations"
         select="
            for $i in $arg
            return
               math:pow(($i - $this-avg), 2)"/>
      <xsl:variable name="max-deviation" select="max($these-deviations)"/>
      <xsl:variable name="this-variance" select="avg($these-deviations)"/>
      <xsl:variable name="this-standard-deviation" select="math:sqrt($this-variance)"/>
      <stats>
         <count>
            <xsl:copy-of select="count($arg)"/>
         </count>
         <sum>
            <xsl:copy-of select="sum($arg)"/>
         </sum>
         <avg>
            <xsl:copy-of select="$this-avg"/>
         </avg>
         <max>
            <xsl:copy-of select="max($arg)"/>
         </max>
         <min>
            <xsl:copy-of select="min($arg)"/>
         </min>
         <var>
            <xsl:copy-of select="$this-variance"/>
         </var>
         <std>
            <xsl:copy-of select="$this-standard-deviation"/>
         </std>
         <xsl:for-each select="$arg">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-dev" select="$these-deviations[$pos]"/>
            <d dev="{$these-deviations[$pos]}">
               <xsl:if test="$this-dev = $max-deviation">
                  <xsl:attribute name="max"/>
               </xsl:if>
               <xsl:value-of select="."/>
            </d>
         </xsl:for-each>
      </stats>
   </xsl:function>

   <xsl:function name="tan:merge-analyzed-stats" as="element()">
      <!-- Input: Results from tan:analyze-stats(); a boolean -->
      <!-- Output: A synthesis of the results. If the second parameter is true, the stats are added; if false, the first statistic will be compared to the sum of all subsequent ones. -->
      <xsl:param name="analyzed-stats" as="element()*"/>
      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:variable name="datum-counts" as="xs:integer*"
         select="
            for $i in $analyzed-stats
            return
               count($i/tan:d)"/>
      <xsl:variable name="this-count" select="avg($analyzed-stats[position() gt 1]/tan:count)"/>
      <xsl:variable name="this-sum" select="avg($analyzed-stats[position() gt 1]/tan:sum)"/>
      <xsl:variable name="this-avg" select="avg($analyzed-stats[position() gt 1]/tan:avg)"/>
      <xsl:variable name="this-max" select="avg($analyzed-stats[position() gt 1]/tan:max)"/>
      <xsl:variable name="this-min" select="avg($analyzed-stats[position() gt 1]/tan:min)"/>
      <xsl:variable name="this-var" select="avg($analyzed-stats[position() gt 1]/tan:var)"/>
      <xsl:variable name="this-std" select="avg($analyzed-stats[position() gt 1]/tan:std)"/>
      <xsl:variable name="this-count-diff" select="$this-count - $analyzed-stats[1]/tan:count"/>
      <xsl:variable name="this-sum-diff" select="$this-sum - $analyzed-stats[1]/tan:sum"/>
      <xsl:variable name="this-avg-diff" select="$this-avg - $analyzed-stats[1]/tan:avg"/>
      <xsl:variable name="this-max-diff" select="$this-max - $analyzed-stats[1]/tan:max"/>
      <xsl:variable name="this-min-diff" select="$this-min - $analyzed-stats[1]/tan:min"/>
      <xsl:variable name="this-var-diff" select="$this-var - $analyzed-stats[1]/tan:var"/>
      <xsl:variable name="this-std-diff" select="$this-std - $analyzed-stats[1]/tan:std"/>
      <xsl:variable name="data-diff" as="element()">
         <stats>
            <count diff="{$this-count-diff div $analyzed-stats[1]/tan:count}">
               <xsl:copy-of select="$this-count-diff"/>
            </count>
            <sum diff="{$this-sum-diff div $analyzed-stats[1]/tan:sum}">
               <xsl:copy-of select="$this-sum-diff"/>
            </sum>
            <avg diff="{$this-avg-diff div $analyzed-stats[1]/tan:avg}">
               <xsl:copy-of select="$this-avg-diff"/>
            </avg>
            <max diff="{$this-max-diff div $analyzed-stats[1]/tan:max}">
               <xsl:copy-of select="$this-max-diff"/>
            </max>
            <min diff="{$this-min-diff div $analyzed-stats[1]/tan:min}">
               <xsl:copy-of select="$this-min-diff"/>
            </min>
            <var diff="{$this-var-diff div $analyzed-stats[1]/tan:var}">
               <xsl:copy-of select="$this-var-diff"/>
            </var>
            <std diff="{$this-std-diff div $analyzed-stats[1]/tan:std}">
               <xsl:copy-of select="$this-std-diff"/>
            </std>
            <xsl:for-each select="$analyzed-stats[1]/tan:d">
               <xsl:variable name="pos" select="position()"/>
               <d>
                  <xsl:copy-of
                     select="avg($analyzed-stats[position() gt 1]/tan:d[$pos]) - $analyzed-stats[1]/tan:d[$pos]"
                  />
               </d>
            </xsl:for-each>
         </stats>
      </xsl:variable>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:merge-analyzed-stats()'"/>
         <xsl:message select="'add stats?', $add-stats"/>
         <xsl:message select="'datum counts:', $datum-counts"/>
         <xsl:message select="'data diff: ', $data-diff"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="$add-stats = true()">
            <xsl:copy-of select="tan:analyze-stats($analyzed-stats/tan:d)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$data-diff"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:blend-color-channel-value" as="xs:double?">
      <!-- Input: two integers and a double between zero and 1 -->
      <!-- Output: a double representing a blend between the first two numbers, interpreted as RGB values -->
      <xsl:param name="color-a" as="xs:double"/>
      <xsl:param name="color-b" as="xs:double"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="color-a-norm" select="$color-a mod 256"/>
      <xsl:variable name="color-b-norm" select="$color-b mod 256"/>
      <xsl:variable name="blend-mid-point-norm" select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:variable name="pass-1" as="xs:double"
         select="((1 - $blend-mid-point-norm) * math:pow($color-a-norm, 2)) + ($blend-mid-point-norm * math:pow($color-b-norm, 2))"
      />
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:blend-color-channel-value()'"/>
         <xsl:message select="'color a norm: ', $color-a-norm"/>
         <xsl:message select="'color b norm: ', $color-b-norm"/>
         <xsl:message select="'blend-mid-point-norm: ', $blend-mid-point-norm"/>
         <xsl:message select="'pass 1: ', $pass-1"/>
      </xsl:if>
      <xsl:value-of select="math:sqrt($pass-1)"/>
   </xsl:function>
   
   <xsl:function name="tan:blend-alpha-value" as="xs:double?">
      <!-- Input: three doubles between zero and 1 -->
      <!-- Output: the blend of the first two doubles, interpreted as alpha values and the third interpreted as a midpoint -->
      <xsl:param name="alpha-a" as="xs:double"/>
      <xsl:param name="alpha-b" as="xs:double"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="alpha-a-norm" select="abs($alpha-a) - floor($alpha-a)"/>
      <xsl:variable name="alpha-b-norm" select="abs($alpha-b) - floor($alpha-b)"/>
      <xsl:variable name="blend-mid-point-norm" select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:value-of select="((1 - $blend-mid-point-norm) * $alpha-a-norm) + ($blend-mid-point-norm * $alpha-b-norm)"/>
   </xsl:function>
   
   <xsl:function name="tan:blend-colors" as="xs:double*">
      <!-- Input: two sequences of doubles (the first three items being from 0 through 255 and the fourth and last between 0 and 1); a double between zero and 1 -->
      <!-- Output: a sequence of doubles representing a blend of the first two sequences, interpreted as RGB colors, and the last double as a desired midpoint -->
      <xsl:param name="rgb-color-1" as="item()+"/>
      <xsl:param name="rgb-color-2" as="item()+"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="blend-mid-point-norm" select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:choose>
         <xsl:when
            test="
               not(every $i in $rgb-color-1
                  satisfies $i castable as xs:double)">
            <xsl:message
               select="'Every item in $rgb-color-1 must be a double or castable as a double'"/>
         </xsl:when>
         <xsl:when
            test="
               not(every $i in $rgb-color-2
                  satisfies $i castable as xs:double)">
            <xsl:message
               select="'Every item in $rgb-color-2 must be a double or castable as a double'"/>
         </xsl:when>
         <xsl:when test="(count($rgb-color-1) lt 3) or (count($rgb-color-1) gt 4) or (count($rgb-color-2) lt 3) or (count($rgb-color-2) gt 4)">
            <xsl:message select="'tan:blend-colors() expects as the first two parameters a sequence of three or four doubles'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'diagnostics on for tan:blend-colors()'"/>
            </xsl:if>
            <xsl:for-each select="1 to 3">
               <xsl:variable name="this-pos" select="."/>
               <xsl:variable name="channel-1" select="xs:double($rgb-color-1[$this-pos])"/>
               <xsl:variable name="channel-2" select="xs:double($rgb-color-2[$this-pos])"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'this channel number: ', $this-pos"/>
                  <xsl:message select="'channel 1 item: ', $rgb-color-1[$this-pos]"/>
                  <xsl:message select="'channel 1 as double: ', $channel-1"/>
                  <xsl:message select="'channel 2 item: ', $rgb-color-2[$this-pos]"/>
                  <xsl:message select="'channel 2 as double: ', $channel-2"/>
               </xsl:if>
               <xsl:value-of select="tan:blend-color-channel-value($channel-1, $channel-2, $blend-mid-point-norm)"/>
            </xsl:for-each>
            <xsl:choose>
               <xsl:when test="not(exists($rgb-color-1[4])) and not(exists($rgb-color-2[4]))"/>
               <xsl:when test="not(exists($rgb-color-1[4]))">
                  <xsl:value-of select="xs:double($rgb-color-2[4])"/>
               </xsl:when>
               <xsl:when test="not(exists($rgb-color-2[4]))">
                  <xsl:value-of select="xs:double($rgb-color-1[4])"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="tan:blend-alpha-value(xs:double($rgb-color-1[4]), xs:double($rgb-color-2[4]), $blend-mid-point-norm)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>


   <!-- Functions: strings -->

   <xsl:function name="tan:namespace" as="xs:string*">
      <!-- Input: any strings representing a namespace prefix or uri -->
      <!-- Output: the corresponding prefix or uri whenever a match is found in the global variable -->
      <xsl:param name="prefix-or-uri" as="xs:string*"/>
      <xsl:for-each select="$prefix-or-uri">
         <xsl:variable name="this-string" select="."/>
         <xsl:value-of
            select="$namespaces-and-prefixes/*[@* = $this-string]/(@*[not(. = $this-string)])[1]"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:glob-to-regex" as="xs:string*">
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
         <xsl:value-of select="concat('^', $pass-3, '$|/', $pass-3, '$')"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:acronym" as="xs:string?">
      <!-- Input: any strings -->
      <!-- Output: the acronym of those strings (initial letters joined without spaces) -->
      <xsl:param name="string-input" as="xs:string*"/>
      <xsl:variable name="initials"
         select="
            for $i in $string-input,
               $j in tokenize($i, '\s+')
            return
               substring($j, 1, 1)"/>
      <xsl:value-of select="string-join($initials, '')"/>
   </xsl:function>

   <xsl:variable name="url-regex" as="xs:string">\S+\.\w+</xsl:variable>
   <xsl:function name="tan:parse-urls" as="element()*">
      <!-- Input: any sequence of strings -->
      <!-- Output: one element per string, parsed into children <non-url> and <url> -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:for-each select="$input-strings">
         <string>
            <xsl:analyze-string select="." regex="{$url-regex}">
               <xsl:matching-substring>
                  <url>
                     <xsl:value-of select="."/>
                  </url>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <non-url>
                     <xsl:value-of select="."/>
                  </non-url>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </string>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:batch-replace-advanced" as="item()*">
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
                  <xsl:apply-templates select="$replace-elements[1]/node()" mode="batch-replace-advanced">
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
   <xsl:template match="*" mode="batch-replace-advanced">
      <xsl:copy>
         <xsl:apply-templates select="@* | node()" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="@*" mode="batch-replace-advanced">
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
   <xsl:template match="text()" mode="batch-replace-advanced">
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
   
   <xsl:variable name="english-prepositions" as="xs:string+"
      select="('aboard', 'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among', 'anti', 'around', 'as', 'at', 'before', 'behind', 'below', 'beneath', 'beside', 'besides', 'between', 'beyond', 'but', 'by', 'concerning', 'considering', 'despite', 'down', 'during', 'except', 'excepting', 'excluding', 'following', 'for', 'from', 'in', 'inside', 'into', 'like', 'minus', 'near', 'of', 'off', 'on', 'onto', 'opposite', 'outside', 'over', 'past', 'per', 'plus', 'regarding', 'round', 'save', 'since', 'than', 'through', 'to', 'toward', 'towards', 'under', 'underneath', 'unlike', 'until', 'up', 'upon', 'versus', 'via', 'with', 'within', 'without')"
   />
   <xsl:variable name="english-articles" as="xs:string+" select="('a', 'the')"/>
   <xsl:function name="tan:title-case" as="xs:string*">
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
                           <xsl:when test=". = ($english-prepositions, $english-articles)">
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
            <xsl:apply-templates select="$pass-1" mode="title-case"/>
         </xsl:variable>
         <xsl:value-of select="string-join($pass-2/*, '')"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:word[1] | tan:word[last()]" mode="title-case">
      <xsl:copy>
         <xsl:value-of select="tan:initial-upper-case(.)"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:initial-upper-case" as="xs:string*">
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
   
   <xsl:function name="tan:commas-and-ands" as="xs:string?">
      <!-- One-parameter version of the full one below -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:value-of select="tan:commas-and-ands($input-strings, true())"/>
   </xsl:function>
   <xsl:function name="tan:commas-and-ands" as="xs:string?">
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


   <!-- Functions: booleans -->

   <xsl:function name="tan:true" as="xs:boolean*">
      <!-- Input: a sequence of strings representing truth values -->
      <!-- Output: the same number of booleans; if the string is some approximation of y, yes, 1, or true, then it is true, and false otherwise -->
      <xsl:param name="string" as="xs:string*"/>
      <xsl:for-each select="$string">
         <xsl:choose>
            <xsl:when test="matches(., '^y(es)?|1|t(rue)?$', 'i')">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:when test="matches(., '^n(o)?|0|f(alse)?$', 'i')">
               <xsl:value-of select="false()"/>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>


   <!-- Functions: nodes -->

   <xsl:function name="tan:node-type" as="xs:string*">
      <!-- Input: any XML items -->
      <!-- Output: the node types of each item -->
      <xsl:param name="xml-items" as="item()*"/>
      <xsl:for-each select="$xml-items">
         <xsl:choose>
            <xsl:when test=". instance of document-node()">document-node</xsl:when>
            <xsl:when test=". instance of comment()">comment</xsl:when>
            <xsl:when test=". instance of processing-instruction()"
               >processing-instruction</xsl:when>
            <xsl:when test=". instance of element()">element</xsl:when>
            <xsl:when test=". instance of attribute()">attribute</xsl:when>
            <xsl:when test=". instance of text()">text</xsl:when>
            <xsl:when test=". instance of xs:boolean">boolean</xsl:when>
            <xsl:when test=". instance of map(*)">map</xsl:when>
            <xsl:when test=". instance of array(*)">array</xsl:when>
            <xsl:otherwise>undefined</xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:group-elements" as="element()*">
      <!-- Input: any elements that should be grouped; parameters specifying minimum size of grouping and the name of a label to prepend -->
      <!-- Output: those elements grouped -->
      <!-- This function was written primarily for the major alter function -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:param name="group-min" as="xs:double?"/>
      <xsl:param name="label-to-prepend"/>
      <xsl:variable name="group-namespace" select="namespace-uri($elements-to-group[1])"/>
      <xsl:variable name="expected-group-size" select="max(($group-min, 1))"/>
      <xsl:choose>
         <xsl:when test="count($elements-to-group) ge $expected-group-size">
            <xsl:element name="group" namespace="{$group-namespace}">
               <xsl:if test="string-length($label-to-prepend) gt 0">
                  <xsl:element name="label" namespace="{$group-namespace}">
                     <xsl:value-of
                        select="tan:evaluate($label-to-prepend, $elements-to-group[1], $elements-to-group)"
                     />
                  </xsl:element>
               </xsl:if>
               <xsl:copy-of select="$elements-to-group"/>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$elements-to-group"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:template match="text()" mode="strip-text"/>

   <xsl:template match="* | comment() | processing-instruction()" mode="text-only">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>

   <xsl:template match="* | processing-instruction() | comment()" mode="prepend-line-break">
      <!-- Useful for breaking up XML content that is not indented -->
      <xsl:text>&#xa;</xsl:text>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:add-attribute" as="element()*">
      <!-- Input: elements; a string and a value -->
      <!-- Output: Each element with an attribute given the name of the string and a value of the value -->
      <xsl:param name="elements-to-change" as="element()*"/>
      <xsl:param name="attribute-name" as="xs:string?"/>
      <xsl:param name="attribute-value" as="item()?"/>
      <xsl:for-each select="$elements-to-change">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="{$attribute-name}">
               <xsl:value-of select="$attribute-value"/>
            </xsl:attribute>
            <xsl:copy-of select="node()"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:tree-to-sequence" as="item()*">
      <!-- Input: any XML fragment -->
      <!-- Output: a flattened sequence of XML nodes representing the original fragment. Each element is given a new @_level 
         specifying the level of hierarchy the element had in the original. Closing tags are specified by <_close-at id=""/>
         with a corresponding @_close-at in the opening tag. Empty elements are retained as-is. -->
      <xsl:param name="xml-fragment" as="item()*"/>
      <xsl:apply-templates select="$xml-fragment" mode="tree-to-sequence">
         <xsl:with-param name="current-level" select="1"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*[node()]" mode="tree-to-sequence">
      <xsl:param name="current-level"/>
      <xsl:variable name="this-id" select="generate-id(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_level" select="$current-level"/>
         <xsl:attribute name="_close-at" select="$this-id"/>
      </xsl:copy>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="current-level" select="$current-level + 1"/>
      </xsl:apply-templates>
      <_close-at id="{$this-id}"/>
   </xsl:template>

   <xsl:function name="tan:sequence-to-tree" as="item()*">
      <!-- One-parameter version of the more complete one below -->
      <xsl:param name="sequence-to-reconstruct" as="item()*"/>
      <xsl:sequence select="tan:sequence-to-tree($sequence-to-reconstruct, false())"/>
   </xsl:function>
   <xsl:function name="tan:sequence-to-tree" as="item()*">
      <!-- Input: a result of tan:tree-to-sequence(); a boolean -->
      <!-- Output: the original tree; if the boolean is true, then any first children that precede the next level 
         will be wrapped in an element like the first child element. -->
      <!-- If a given opening tag has a corresponding <_close-at> then what is between will become the children
         of the element, and what comes after its following siblings. -->
      <!-- This is the inverse of the function tan:tree-to-sequence(). That is, tan:sequence-to-tree($i) => 
         tan:tree-to-sequence() should result in a copy of $i. -->
      <!-- This function is especially helpful for a raw text transcription that needs to be converted to a
         class-1 body via the inline numerical references. The technique is to replace the numerical references 
         with empty <div>s, each one with @n and @type correctly assessed based on the match, and a @_level to 
         specify where in the hierarchy it should sit. -->
      <!-- You may wish to run the results of this output through tan:consolidate-identical-adjacent-divs() -->
      <xsl:param name="sequence-to-reconstruct" as="item()*"/>
      <xsl:param name="fix-orphan-text" as="xs:boolean"/>
      <xsl:variable name="sequence-prepped" as="element()">
         <tree>
            <xsl:copy-of select="$sequence-to-reconstruct"/>
         </tree>
      </xsl:variable>
      <xsl:variable name="results" as="element()">
         <xsl:apply-templates select="$sequence-prepped" mode="sequence-to-tree">
            <xsl:with-param name="level-so-far" select="0"/>
            <xsl:with-param name="fix-orphan-text" select="$fix-orphan-text" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:copy-of select="$results/node()"/>
   </xsl:function>
   <xsl:template match="*[*[@_level]]" mode="sequence-to-tree">
      <xsl:param name="level-so-far" as="xs:integer"/>
      <xsl:param name="fix-orphan-text" as="xs:boolean" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="first-child-element" select="*[1]"/>
      <xsl:variable name="level-to-process" select="$level-so-far + 1"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="node()" group-starting-with="*[@_level = $level-to-process]">
            <xsl:variable name="this-head" select="current-group()[1]"/>
            <xsl:variable name="this-is-new-group" as="xs:boolean" select="($this-head/@_level = $level-to-process, false())[1]"/>
            <xsl:variable name="this-close-at-id" select="$this-head/@_close-at"/>
            <xsl:variable name="new-group" as="item()*">
               <xsl:if test="$this-is-new-group">
                  <xsl:for-each-group select="current-group()" group-starting-with="tan:_close-at[@id = $this-close-at-id]">
                     <xsl:choose>
                        <xsl:when test="current-group()[1][@id = $this-close-at-id]">
                           <xsl:copy-of select="tail(current-group())"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:element name="{name($this-head)}" namespace="{namespace-uri($this-head)}">
                              <xsl:copy-of select="$this-head/(@* except (@level | @_close-at))"/>
                              <xsl:copy-of select="tail(current-group())"/>
                           </xsl:element>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each-group> 
               </xsl:if>
            </xsl:variable>
            <xsl:choose>
               <xsl:when test="not($this-is-new-group) and $fix-orphan-text">
                  <xsl:element name="{name($first-child-element)}"
                     namespace="{namespace-uri($first-child-element)}">
                     <xsl:copy-of select="$first-child-element/(@* except (@_level | @_close-at))"/>
                     <xsl:copy-of select="current-group()"/>
                  </xsl:element>

               </xsl:when>
               <xsl:when test="not($this-is-new-group) or not(exists($new-group))">
                  <xsl:copy-of select="current-group()"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="$new-group" mode="#current">
                     <xsl:with-param name="level-so-far" select="$level-to-process"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:consolidate-identical-adjacent-divs" as="item()*">
      <!-- Input: various items -->
      <!-- Output: the items, but with any adjacent divs with exactly the same values of @type and @n consolidated -->
      <!-- This function was developed to clean up the results of tan:sequence-to-tree() -->
      <xsl:param name="items-with-divs-to-consolidate" as="item()*"/>
      <xsl:apply-templates select="$items-with-divs-to-consolidate"
         mode="consolidate-identical-adjacent-divs"/>
   </xsl:function>
   <xsl:template match="*[*:div]" mode="consolidate-identical-adjacent-divs">
      <xsl:variable name="these-divs" select="*:div"/>
      <xsl:variable name="this-div-namespace" select="namespace-uri(*:div[1])"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node() except ($these-divs | $these-divs/preceding-sibling::node()[1]/self::text())"/>
         <xsl:for-each-group select="$these-divs"
            group-adjacent="string-join((@type, @n), '#')">
            <xsl:variable name="new-group" as="element()">
               <xsl:element name="div" namespace="{$this-div-namespace}">
                  <xsl:copy-of select="current-group()[1]/@*"/>
                  <xsl:copy-of select="current-group()/node()"/>
               </xsl:element>
            </xsl:variable>
            <xsl:copy-of select="current-group()[1]/preceding-sibling::node()[1]/text()"/>
            <xsl:apply-templates select="$new-group" mode="#current"/>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:function name="tan:remove-duplicate-siblings" as="item()*">
      <xsl:param name="items-to-process" as="item()*"/>
      <xsl:apply-templates select="$items-to-process" mode="remove-duplicate-siblings"/>
   </xsl:function>
   <xsl:function name="tan:remove-duplicate-siblings" as="item()*">
      <!-- Input: any items -->
      <!-- Output: the same documents after removing duplicate elements whose names match the second parameter. -->
      <!-- This function is applied during document resolution, to prune duplicate elements that might have been included -->
      <xsl:param name="items-to-process" as="document-node()*"/>
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:apply-templates select="$items-to-process" mode="remove-duplicate-siblings">
         <xsl:with-param name="element-names-to-check" select="$element-names-to-check"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*" mode="remove-duplicate-siblings">
      <xsl:param name="element-names-to-check" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="check-this-element" select="not(exists($element-names-to-check))
         or ($element-names-to-check = '*')
         or ($element-names-to-check = name(.))"/>
      <xsl:choose>
         <xsl:when
            test="
               ($check-this-element = true()) and (some $i in preceding-sibling::*
                  satisfies deep-equal(., $i))"
         />
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:template match="text() | comment() | processing-instruction()" mode="filter-elements"/>
   <xsl:template match="document-node()" mode="filter-elements">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="*" mode="filter-elements">
      <xsl:param name="keep-elements-whose-names-match" as="xs:string?" tunnel="yes"/>
      <xsl:param name="keep-elements-whose-names-do-not-match" as="xs:string?" tunnel="yes"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:choose>
         <xsl:when test="string-length($keep-elements-whose-names-do-not-match) gt 0 
            and not(matches($this-name, $keep-elements-whose-names-do-not-match))">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when test="string-length($keep-elements-whose-names-match) gt 0 
            and matches($this-name, $keep-elements-whose-names-match)">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <!-- Processing diff and collate output -->
   
   <xsl:function name="tan:infuse-diff-and-collate-stats" as="element()?">
      <!-- Input: output from tan:diff() or tan:collate(); perhaps elements defining unimportant changes (see below) -->
      <!-- Output: the output wrapped in a <group>, whose first child is <stats>, supplying statistics for the difference
      or collation. A collation will also include a <venns> with statistical analysis of sources as statistics suitable for 
      3-way Venn diagrams. The diff output will be imprinted with @_pos and @_len, to put it on par with the output of 
      tan:collate(), where the position of each string can be calculated -->
      <!-- Unimportant changes (2nd parameter) are elements of any name, grouping <c>s. Each group of <c>s will be treated
      as equivalent. For example, to treat the ' and " as statistically irrelevant, supply <alias><c>'</c><c>"</c></alias> -->
      
      <xsl:param name="diff-or-collate-input" as="element()?"/>
      <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
      <xsl:variable name="input-prepped" as="element()">
         <group>
            <xsl:copy-of select="$diff-or-collate-input"/>
         </group>
      </xsl:variable>
      <xsl:apply-templates select="$input-prepped" mode="infuse-diff-and-collate-stats">
         <xsl:with-param name="unimportant-change-character-aliases"
            select="$unimportant-change-character-aliases" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <!-- To use the following template mode, wrap the results of tan:diff() or tan:collate() in some element (doesn't matter what
   its name is). The output will be the same node, but with an infusion of statistics. -->
   
   <xsl:template match="*[tan:diff]" mode="infuse-diff-and-collate-stats">
      <xsl:param name="unimportant-change-character-aliases" as="element()*" tunnel="yes"/>
      <xsl:variable name="these-as" select="tan:diff/tan:a"/>
      <xsl:variable name="these-bs" select="tan:diff/tan:b"/>
      <xsl:variable name="these-commons" select="tan:diff/tan:common"/>
      <xsl:variable name="these-a-lengths"
         select="
            for $i in $these-as
            return
               string-length($i)"/>
      <xsl:variable name="these-b-lengths"
         select="
            for $i in $these-bs
            return
               string-length($i)"/>
      
      <xsl:variable name="unique-a-length" select="sum($these-a-lengths)"/>
      <xsl:variable name="unique-b-length" select="sum($these-b-lengths)"/>
      <xsl:variable name="this-common-length" select="string-length(string-join($these-commons))"/>
      <xsl:variable name="orig-a-length" select="$unique-a-length + $this-common-length"/>
      <xsl:variable name="orig-b-length" select="$unique-b-length + $this-common-length"/>
      
      <xsl:variable name="these-character-alias-exceptions" as="element()">
         <exceptions>
            <xsl:for-each-group select="tan:diff/*" group-ending-with="tan:common">
               <xsl:variable name="this-a" select="current-group()/self::tan:a"/>
               <xsl:variable name="this-b" select="current-group()/self::tan:b"/>
               <xsl:variable name="this-char-alias"
                  select="$unimportant-change-character-aliases[tan:c = $this-a][tan:c = $this-b]"/>
               <group>
                  <xsl:if test="exists($this-char-alias)">
                     <xsl:copy-of select="$this-a"/>
                     <xsl:copy-of select="$this-b"/>
                  </xsl:if>
               </group>
            </xsl:for-each-group>
         </exceptions>
      </xsl:variable>
      <!--<xsl:variable name="this-exception-length" select="count($these-character-alias-exceptions)"/>-->
      <xsl:variable name="exception-a-length"
         select="string-length(string-join($these-character-alias-exceptions/*/tan:a))"/>
      <xsl:variable name="exception-b-length"
         select="string-length(string-join($these-character-alias-exceptions/*/tan:b))"/>
      
      <xsl:variable name="unique-a-length-adjusted" select="$unique-a-length - $exception-a-length"/>
      <xsl:variable name="unique-b-length-adjusted" select="$unique-b-length - $exception-b-length"/>
      
      <xsl:variable name="this-full-length" select="string-length(tan:diff)"/>

      <!--<xsl:variable name="this-a-length" select="$orig-a-length - $this-exception-length"/>
      <xsl:variable name="this-b-length" select="$orig-b-length - $this-exception-length"/>-->
      <xsl:variable name="unique-a-portion" select="$unique-a-length-adjusted div $orig-a-length"/>
      <xsl:variable name="unique-b-portion" select="$unique-b-length-adjusted div $orig-b-length"/>
      <xsl:variable name="unique-both-portion" select="($unique-a-length-adjusted + $unique-b-length-adjusted) div $this-full-length"/>
      

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <stats>
            <witness id="a" class="e-a">
               <xsl:copy-of select="tan:file[1]/@ref"/>
               <uri>
                  <xsl:value-of select="tan:file[1]/@uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$orig-a-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-as) - count($these-character-alias-exceptions/*/tan:a)"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-a-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-a-portion, '0.0%')"/>
               </diff-portion>
            </witness>
            <witness id="b" class="e-b">
               <xsl:copy-of select="tan:file[2]/@ref"/>
               <uri>
                  <xsl:value-of select="tan:file[2]/@uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$orig-b-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-bs) - count($these-character-alias-exceptions/*/tan:b)"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-b-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-b-portion, '0.0%')"/>
               </diff-portion>
            </witness>
            <diff id="diff" class="a-diff">
               <uri>
                  <xsl:value-of select="@_target-uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$this-full-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-character-alias-exceptions/*[not(*)])"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-a-length-adjusted + $unique-b-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-both-portion, '0.0%')"/>
               </diff-portion>
            </diff>
            <xsl:if test="exists($these-character-alias-exceptions/*/*)">
               <note>
                  <xsl:text>The statistics above exclude differences of </xsl:text>
                  <xsl:value-of
                     select="
                        string-join(for $i in tan:distinct-items($these-character-alias-exceptions/*)
                        return
                           string-join($i/tan:c, ' and '), '; ')"/>
                  <xsl:text>.</xsl:text>
               </note>
            </xsl:if>
         </stats>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
    
   <xsl:template match="tan:diff" mode="infuse-diff-and-collate-stats">
      <xsl:copy-of select="tan:stamp-diff-with-text-data(.)"/>
   </xsl:template>
    
   <xsl:template match="*[tan:collation]" mode="infuse-diff-and-collate-stats">
      <xsl:param name="unimportant-change-character-aliases" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-group" select="."/>
      <xsl:variable name="all-us" select="tan:collation/tan:u"/>
      <xsl:variable name="all-u-groups" as="element()">
         <u-groups>
            <!--  group-by="tokenize(@w, ' ')" -->
            <xsl:for-each-group select="$all-us" group-by="tan:wit/@ref">
               <xsl:sort
                  select="
                     if (current-grouping-key() castable as xs:integer) then
                        xs:integer(current-grouping-key())
                     else
                        0"/>
               <xsl:sort select="current-grouping-key()"/>
               <group n="{current-grouping-key()}">
                  <xsl:copy-of select="current-group()"/>
               </group>
            </xsl:for-each-group>
         </u-groups>
      </xsl:variable>
      <xsl:variable name="this-target-uri" select="@_target-uri"/>
      <!--<xsl:variable name="this-full-length" select="string-length(string-join(tan:collation/(* except tan:witness)))"/>-->
      <xsl:variable name="this-full-length"
         select="string-length(string-join(tan:collation/*/tan:txt))"/>

      <xsl:variable name="us-excepted-by-character-alias-exceptions" as="element()*">
         <xsl:for-each-group select="tan:collation/tan:u"
            group-adjacent="
               for $i in tan:txt
               return
                  ($unimportant-change-character-aliases[tan:c = $i]/@n, '')[1]">
            <xsl:variable name="these-us" select="current-group()"/>

            <xsl:variable name="is-for-every-ref"
               select="
                  every $i in $this-group/tan:file/@ref
                     satisfies exists($these-us/tan:wit[@ref = $i])"/>

            <xsl:if test="(string-length(current-grouping-key()) gt 0) and $is-for-every-ref">
               <xsl:sequence select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="this-exception-length"
         select="count($us-excepted-by-character-alias-exceptions)"/>

      <xsl:variable name="this-common-length"
         select="string-length(string-join(tan:collation/tan:c/tan:txt))"/>

      <xsl:variable name="this-collation-diff-length"
         select="string-length(string-join($all-us/tan:txt))"/>
      <xsl:variable name="these-files" select="tan:file"/>
      <xsl:variable name="this-file-count" select="count($these-files)"/>
      <xsl:variable name="these-witnesses" select="tan:collation/tan:witness"/>
      <xsl:variable name="basic-stats" as="element()">
         <stats>
            <xsl:for-each select="$these-files">
               <xsl:variable name="this-pos" select="position()"/>
               <xsl:variable name="this-label"
                  select="string(($these-witnesses[$this-pos]/@id, $this-pos)[1])"/>
               <xsl:variable name="this-diff-group" select="$all-u-groups/tan:group[$this-pos]"/>
               <xsl:variable name="these-diffs" select="$this-diff-group/tan:u"/>
               <xsl:variable name="these-diff-exceptions"
                  select="$us-excepted-by-character-alias-exceptions[tan:wit/@ref = $this-label]"/>
               <xsl:variable name="this-exception-length" select="count($these-diff-exceptions)"/>
               <xsl:variable name="this-diff-length"
                  select="string-length(string-join($these-diffs)) - $this-exception-length"/>
               <xsl:variable name="this-diff-portion"
                  select="$this-diff-length div ($this-common-length + $this-diff-length + $this-exception-length)"/>
               <witness class="{'a-w-' || @ref}">
                  <xsl:copy-of select="@ref"/>
                  <uri>
                     <xsl:value-of select="@uri"/>
                  </uri>
                  <length>
                     <xsl:value-of select="@length"/>
                  </length>
                  <diff-count>
                     <xsl:value-of
                        select="count($these-diffs[tan:txt]) - count($these-diff-exceptions)"/>
                  </diff-count>
                  <diff-length>
                     <xsl:value-of select="$this-diff-length"/>
                  </diff-length>
                  <diff-portion>
                     <xsl:value-of select="format-number($this-diff-portion, '0.0%')"/>
                  </diff-portion>
               </witness>
            </xsl:for-each>
         </stats>
      </xsl:variable>

      <!-- 3-way venns, to calculate distance of any version between any two others -->
      <xsl:variable name="three-way-venns" as="element()">
         <venns>
            <xsl:if test="$this-file-count ge 3">
               <xsl:for-each select="1 to ($this-file-count - 2)">
                  <xsl:variable name="this-a-pos" select="."/>
                  <xsl:variable name="this-a-label" select="$this-group/tan:file[$this-a-pos]/@ref"/>
                  <xsl:for-each select="($this-a-pos + 1) to ($this-file-count - 1)">
                     <xsl:variable name="this-b-pos" select="."/>
                     <xsl:variable name="this-b-label"
                        select="$this-group/tan:file[$this-b-pos]/@ref"/>
                     <xsl:for-each select="($this-b-pos + 1) to $this-file-count">
                        <xsl:variable name="this-c-pos" select="."/>
                        <xsl:variable name="this-c-label"
                           select="$this-group/tan:file[$this-c-pos]/@ref"/>
                        <xsl:variable name="all-relevant-nodes"
                           select="$this-group/tan:collation/*[tan:wit[@ref = ($this-a-label, $this-b-label, $this-c-label)]]"/>

                        <xsl:variable name="these-excepted-us" as="element()*">
                           <xsl:for-each-group select="$all-relevant-nodes/self::tan:u"
                              group-adjacent="
                                 for $i in tan:txt
                                 return
                                    ($unimportant-change-character-aliases[c = $i]/@n, '')[1]">
                              <xsl:variable name="is-for-every-ref"
                                 select="
                                    (current-group()/tan:wit/@ref = $this-a-label) and (current-group()/tan:wit/@ref = $this-b-label)
                                    and (current-group()/tan:wit/@ref = $this-c-label)"/>
                              <xsl:if
                                 test="(string-length(current-grouping-key()) gt 0) and $is-for-every-ref">
                                 <xsl:sequence select="current-group()"/>
                              </xsl:if>
                           </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:variable name="this-exception-length"
                           select="count($these-excepted-us)"/>

                        <xsl:variable name="this-full-length"
                           select="string-length(string-join($all-relevant-nodes))"/>
                        <xsl:variable name="these-a-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-a-label]"/>
                        <xsl:variable name="these-b-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-b-label]"/>
                        <xsl:variable name="these-c-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-c-label]"/>
                        <!-- The seven parts of a 3-way venn diagram -->
                        <xsl:variable name="these-a-only-nodes"
                           select="$these-a-nodes except ($these-b-nodes, $these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-b-only-nodes"
                           select="$these-b-nodes except ($these-a-nodes, $these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-c-only-nodes"
                           select="$these-c-nodes except ($these-a-nodes, $these-b-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-b-only-nodes"
                           select="($these-a-nodes intersect $these-b-nodes) except ($these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-c-only-nodes"
                           select="($these-a-nodes intersect $these-c-nodes) except ($these-b-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-b-c-only-nodes"
                           select="($these-b-nodes intersect $these-c-nodes) except ($these-a-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-b-and-c-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-a-label][tan:wit/@ref = $this-b-label][tan:wit/@ref = $this-c-label], $these-excepted-us"/>
                        <xsl:variable name="length-a-only"
                           select="string-length(string-join($these-a-only-nodes))"/>
                        <xsl:variable name="length-b-only"
                           select="string-length(string-join($these-b-only-nodes))"/>
                        <xsl:variable name="length-c-only"
                           select="string-length(string-join($these-c-only-nodes))"/>
                        <xsl:variable name="length-a-b-only"
                           select="string-length(string-join($these-a-b-only-nodes))"/>
                        <xsl:variable name="length-a-c-only"
                           select="string-length(string-join($these-a-c-only-nodes))"/>
                        <xsl:variable name="length-b-c-only"
                           select="string-length(string-join($these-b-c-only-nodes))"/>
                        <xsl:variable name="length-a-b-and-c"
                           select="string-length(string-join($these-a-b-and-c-nodes))"/>
                        <venn>
                           <a>
                              <xsl:value-of select="$this-a-label"/>
                           </a>
                           <b>
                              <xsl:value-of select="$this-b-label"/>
                           </b>
                           <c>
                              <xsl:value-of select="$this-c-label"/>
                           </c>
                           <node-count>
                              <xsl:value-of select="count($all-relevant-nodes)"/>
                           </node-count>
                           <length>
                              <xsl:value-of select="$this-full-length"/>
                           </length>
                           <part>
                              <a/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <b/>
                              <node-count>
                                 <xsl:value-of select="count($these-b-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-b-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-b-only div $this-full-length"/>
                              </portion>
                              <texts>
                                 <xsl:for-each select="$these-b-only-nodes">
                                    <xsl:copy>
                                       <xsl:copy-of select="tan:txt"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-b-label]"/>
                                    </xsl:copy>
                                 </xsl:for-each>
                              </texts>
                           </part>
                           <part>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-c-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <b/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-b-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-b-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-b-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-c-only div $this-full-length"/>
                              </portion>
                              <texts>
                                 <xsl:for-each select="$these-a-c-only-nodes">
                                    <xsl:copy>
                                       <xsl:copy-of select="tan:txt"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-a-label]"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-c-label]"/>
                                    </xsl:copy>
                                 </xsl:for-each>
                              </texts>
                           </part>
                           <part>
                              <b/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-b-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-b-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-b-c-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <b/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-b-and-c-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-b-and-c"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-b-and-c div $this-full-length"/>
                              </portion>
                           </part>
                           <xsl:if test="$this-exception-length gt 0">
                              <note>
                                 <xsl:text>The statistics above exclude differences consisting exclusively of </xsl:text>
                                 <xsl:value-of
                                    select="
                                       string-join(for $i in tan:distinct-items($unimportant-change-character-aliases)
                                       return
                                          string-join($i/c, ' versus '), '; ')"/>
                                 <xsl:text>.</xsl:text>
                              </note>
                           </xsl:if>
                        </venn>
                     </xsl:for-each>
                  </xsl:for-each>
               </xsl:for-each>
            </xsl:if>
         </venns>
      </xsl:variable>


      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <stats>
            <xsl:copy-of select="$basic-stats/*"/>
            <collation id="collation" class="a-collation">
               <uri>
                  <xsl:value-of select="$this-target-uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$this-full-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($all-us[tan:txt])"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$this-collation-diff-length"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of
                     select="format-number(($this-collation-diff-length div $this-full-length), '0.0%')"
                  />
               </diff-portion>
            </collation>
            <xsl:if test="$this-exception-length gt 0">
               <note>
                  <xsl:text>The statistics above exclude differences consisting exclusively of </xsl:text>
                  <xsl:value-of
                     select="
                        string-join(for $i in tan:distinct-items($unimportant-change-character-aliases)
                        return
                           string-join($i/c, ' versus '), '; ')"/>
                  <xsl:text>.</xsl:text>
               </note>
            </xsl:if>
            <xsl:copy-of select="$three-way-venns"/>
         </stats>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
   
   
   <xsl:function name="tan:diff-a-map" as="map(xs:integer, item()*)?">
      <!-- Input: the result of tan:diff() -->
      <!-- Output: a map with integer entries representing the position of each a character, corresponding to the string value 
         of its b counterpart. Characters that are added, and not just replaced, are wrapped in <add> -->
      <!-- This function is used to make swaps from one text to another, where the replacement must take place 
         character-by-character, such as in the dependent function tan:replace-diff() -->
      <xsl:param name="diff-to-map" as="element(tan:diff)?"/>
      <xsl:variable name="diff-stamped" select="tan:stamp-diff-with-text-data($diff-to-map)"/>
      <xsl:apply-templates select="$diff-stamped" mode="diff-a-map"/>
   </xsl:function>
   
   <xsl:template match="tan:diff" mode="diff-a-map">
      <xsl:map>
         <xsl:apply-templates mode="#current"/>
      </xsl:map>
   </xsl:template>
   <xsl:template match="tan:b" mode="diff-a-map"/>
   <xsl:template match="tan:common[@_pos = '1']" priority="1" mode="diff-a-map">
      <xsl:variable name="prev-b" select="preceding-sibling::tan:b"/>
      <!--<xsl:variable name="use-prev-b" select="not(exists(preceding-sibling::tan:a))"/>-->
      <!-- Yes the next sibling might be an a, but in that case, we shouldn't grab the b, because that a will get it. -->
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b[text()]"/>
      <xsl:variable name="these-chars" select="string-to-codepoints(.)"/>
      <xsl:variable name="char-count" select="count($these-chars)"/>
      <xsl:for-each select="$these-chars">
         <xsl:map-entry key="position()">
            <xsl:choose>
               <xsl:when test="position() eq 1 and position() eq $char-count">
                  <xsl:if test="exists($prev-b)">
                     <add><xsl:value-of select="$prev-b"/></add>
                  </xsl:if>
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:when test="position() eq 1">
                  <xsl:if test="exists($prev-b)">
                     <add><xsl:value-of select="$prev-b"/></add>
                  </xsl:if>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:when>
               <xsl:when test="position() eq $char-count">
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:otherwise>
            </xsl:choose>
            
         </xsl:map-entry>
      </xsl:for-each>
      
   </xsl:template>
   <xsl:template match="tan:common" mode="diff-a-map">
      <xsl:variable name="last-end" select="xs:integer(@_pos) - 1"/>
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b[text()]"/>
      <xsl:variable name="these-chars" select="string-to-codepoints(.)"/>
      <xsl:variable name="char-count" select="count($these-chars)"/>
      <xsl:for-each select="$these-chars">
         <xsl:map-entry key="position() + $last-end">
            <xsl:choose>
               <xsl:when test="position() eq $char-count">
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:map-entry>
      </xsl:for-each>
   </xsl:template>
   <xsl:template match="tan:a" mode="diff-a-map">
      <xsl:variable name="last-end" select="xs:integer(@_pos) - 1"/>
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b"/>
      <xsl:variable name="char-count" select="xs:integer(@_len)"/>
      <xsl:variable name="this-remnant" select="substring($this-corresponding-b, $char-count + 1)"/>
      <xsl:for-each select="1 to $char-count">
         <xsl:map-entry key=". + $last-end">
            <xsl:if test=". = 1">
               <xsl:value-of select="substring($this-corresponding-b, 1, $char-count)"/>
               <xsl:if test="string-length($this-remnant) gt 0">
                  <add><xsl:value-of select="$this-remnant"/></add>
               </xsl:if>
            </xsl:if>
         </xsl:map-entry>
      </xsl:for-each>
   </xsl:template>
   
   
   
   <xsl:function name="tan:replace-diff" as="element()?">
      <!-- Input: the results of tan:diff(); the original a and b strings -->
      <!-- Output: the output, but with each <a>, and <b> replaced by the original strings. <common> follows the a string, not b. -->
      <!-- This function was made to support a more relaxed approach to tan:diff(), one that avoids changes that should be ignored.
      For example, if you are comparing "Gray" (=$a) and "greys" (=$b) and for your purposes, alternate spellings and case should be 
      ignored, then make appropriate changes to the strings (=$a2, $b2) then tan:reconcile-diff($a, $b, tan:diff($a2, $b2)) will result 
      in <diff><common>Gray</common><b>s</b></diff> -->
      <xsl:param name="original-string-a" as="xs:string?"/>
      <xsl:param name="original-string-b" as="xs:string?"/>
      <xsl:param name="diff-to-replace" as="element()?"/>
      
      <xsl:variable name="diff-a" select="string-join($diff-to-replace/(tan:common | tan:a))"/>
      <xsl:variable name="diff-b" select="string-join($diff-to-replace/(tan:common | tan:b))"/>
      
      <xsl:variable name="a2-to-a-diff" select="tan:diff($diff-a, $original-string-a, false())"/>
      <xsl:variable name="b2-to-b-diff" select="tan:diff($diff-b, $original-string-b, false())"/>
      
      <xsl:variable name="a2-to-a-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($a2-to-a-diff)"/>
      <xsl:variable name="b2-to-b-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($b2-to-b-diff)"/>
      
      <xsl:variable name="diff-to-replace-stamped" select="tan:stamp-diff-with-text-data($diff-to-replace)"/>
      
      <xsl:variable name="output-pass-1" as="element()">
         <xsl:apply-templates select="$diff-to-replace-stamped" mode="replace-diff">
            <xsl:with-param name="a2-to-a-diff-map" tunnel="yes" select="$a2-to-a-diff-map"/>
            <xsl:with-param name="b2-to-b-diff-map" tunnel="yes" select="$b2-to-b-diff-map"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      <xsl:variable name="output-pass-2" as="element()">
         <!-- If there are tail-end additions shared by an a or commond with the next b, then normally they should be delayed -->
         <diff>
            <xsl:for-each-group select="$output-pass-1/*" group-adjacent="exists(tan:add[not(following-sibling::node())])">
               <xsl:choose>
                  <xsl:when test="(current-grouping-key() = true())">
                     <xsl:for-each-group select="current-group()" group-ending-with="tan:b">
                        <xsl:variable name="group-count" select="count(current-group())"/>
                        <xsl:choose>
                           <xsl:when test="exists(current-group()[last()]/self::tan:b)">
                              <xsl:variable name="penultimate-item" select="current-group()[position() eq ($group-count - 1)]"/>
                              <xsl:variable name="last-item" select="current-group()[last()]"/>
                              <xsl:variable name="first-add"
                                 select="$penultimate-item/tan:add[not(following-sibling::node())]"/>
                              <xsl:variable name="second-add"
                                 select="$last-item/tan:add[not(following-sibling::node())]"/>
                              <xsl:copy-of select="current-group() except ($penultimate-item, $last-item)"/>
                              <xsl:for-each select="$penultimate-item, $last-item">
                                 <xsl:copy>
                                    <xsl:apply-templates select="node() except tan:add[not(following-sibling::node())]" mode="shallow-skip-diff-add"/>
                                 </xsl:copy>
                              </xsl:for-each>
                              <xsl:copy-of select="tan:diff($first-add, $second-add, false())/*"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:apply-templates select="current-group()" mode="shallow-skip-diff-add"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each-group> 
                     
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates select="current-group()" mode="shallow-skip-diff-add"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each-group> 
         </diff>
         
      </xsl:variable>
      
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:adjust-diff()'"/>
         <xsl:message select="'Orig string a: ' || $original-string-a"/>
         <xsl:message select="'Orig string b: ' || $original-string-b"/>
         <xsl:message select="'Diff to adjust: ', $diff-to-replace"/>
      </xsl:if>
      
      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Replacing output of tan:replace-diff() with diagnostic output'"/>
            <testing>
               <a2-to-a-diff><xsl:copy-of select="$a2-to-a-diff"/></a2-to-a-diff>
               <b2-to-b-diff><xsl:copy-of select="$b2-to-b-diff"/></b2-to-b-diff>
               <a2-to-a-map><xsl:value-of select="map:for-each($a2-to-a-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></a2-to-a-map>
               <b2-to-b-map><xsl:value-of select="map:for-each($b2-to-b-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></b2-to-b-map>
               <diff-to-replace-stamped><xsl:copy-of select="$diff-to-replace-stamped"/></diff-to-replace-stamped>
               <out-pass1><xsl:copy-of select="$output-pass-1"/></out-pass1>
               <out-pass2><xsl:copy-of select="$output-pass-2"/></out-pass2>
            </testing>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="tan:adjust-diff($output-pass-2)"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:template match="tan:common | tan:a" mode="replace-diff">
      <xsl:param name="a2-to-a-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:copy>
         <xsl:sequence
            select="
               for $i in ($this-start to $this-end)
               return
                  map:get($a2-to-a-diff-map, $i)"
         />
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:b" mode="replace-diff">
      <xsl:param name="b2-to-b-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:copy>
         <xsl:sequence
            select="
               for $i in ($this-start to $this-end)
               return
                  map:get($b2-to-b-diff-map, $i)"
         />
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:add" mode="shallow-skip-diff-add">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   
   <xsl:function name="tan:replace-collation" as="element()?">
      <!-- Input: two strings; the output of tan:collate() (2020 version only, for XSLT 3.0) -->
      <!-- Output: the output, but an attempt is made to change every <c> and every <u> with the chosen witness 
         id (param 2) into the original string form (param 1). -->
      <!-- This is a companion function to tan:replace-diff(), but it has some inherent limitations. Diffs of 3 or
      more sources can be messy, and any attempt to replace every <u> with a particular version proves to be confusing 
      to interpret. Furthermore, tan:replace-diff() adjusts the output so that newly inserted characters
      are not repeated if they are applied equally to coordinate <a>s and <b>s. That is not possible for collate because
      of how chaotic the results can be. So the fallback method is to focus on getting the first witness right, and not
      worrying about the others. -->
      <!-- If the 2nd parameter is empty or doesn't match a particular witness id, then the first witness will be chosen.
      Intentionally supplying a bad 2nd parameter can be a good idea, if you are interested in only the dominant source, 
      since tan:collate() by default places at the top the witness with the least amount of divergence. -->
      <!-- Because only one witness is being recalibrated, it is possible to update the position values. But the other
      witness values will not be updated, so that the results can be correlated with the other witness texts if needed.
      Further, if a replacement involves that witness no longer attesting to that fragment, then it is changed to a <u>
      (or the <u> is retained) and the <wit> is dropped. -->
      <xsl:param name="original-witness-string" as="xs:string?"/>
      <xsl:param name="original-witness-id" as="xs:string?"/>
      <xsl:param name="collate-output-to-replace" as="element()?"/>
      
      <xsl:variable name="picked-id-fixed"
         select="
            if ($original-witness-id = $collate-output-to-replace/tan:witness/@id) then
               $original-witness-id
            else
               $collate-output-to-replace/tan:witness[1]/@id"
      />
      <xsl:variable name="picked-witness-text"
         select="string-join($collate-output-to-replace/*[tan:wit/@ref = $picked-id-fixed]/tan:txt)"
      />
      <xsl:variable name="wit2-to-wit-diff" select="tan:diff($picked-witness-text, $original-witness-string, false())"/>
      
      <xsl:variable name="wit2-to-wit-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($wit2-to-wit-diff)"/>
      
      <xsl:variable name="output-pass-1" as="element()?">
         <xsl:apply-templates select="$collate-output-to-replace" mode="replace-collation">
            <xsl:with-param name="wit-id" tunnel="yes" select="$picked-id-fixed"/>
            <xsl:with-param name="wit-diff-map" tunnel="yes" select="$wit2-to-wit-diff-map"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Replacing output of tan:replace-collate() with diagnostic output'"/>
            <testing>
               <picked-id-fixed><xsl:value-of select="$picked-id-fixed"/></picked-id-fixed>
               <orig-witness-text><xsl:value-of select="$original-witness-string"/></orig-witness-text>
               <collate-witness-text><xsl:value-of select="$picked-witness-text"/></collate-witness-text>
               <wit2-to-wit-diff><xsl:copy-of select="$wit2-to-wit-diff"/></wit2-to-wit-diff>
               <wit2-to-wit-map><xsl:value-of select="map:for-each($wit2-to-wit-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></wit2-to-wit-map>
               <output-pass-1><xsl:copy-of select="$output-pass-1"/></output-pass-1>
            </testing>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$output-pass-1"/>
         </xsl:otherwise>
      </xsl:choose>
      
      
   </xsl:function>
   
   <xsl:template match="tan:collation" mode="replace-collation">
      <xsl:param name="wit-id" tunnel="yes" as="xs:string?"/>
      <xsl:param name="wit-diff-map" tunnel="yes" as="map(xs:integer, item()*)?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="* except (tan:u | tan:c)"/>
         <xsl:iterate select="tan:u | tan:c">
            <xsl:param name="orig-last-pos" as="xs:integer" select="0"/>
            <xsl:param name="new-last-pos" as="xs:integer" select="0"/>
            
            <xsl:variable name="this-is-relevant" select="tan:wit/@ref = $wit-id"/>
            <xsl:variable name="these-txt-charpoints" select="string-to-codepoints(tan:txt)"/>
            <xsl:variable name="these-text-replacements" as="xs:string*">
               <xsl:for-each select="$these-txt-charpoints">
                  <xsl:variable name="this-pos" select="position()"/>
                  <xsl:variable name="this-map-value" as="item()*" select="map:get($wit-diff-map, $orig-last-pos + $this-pos)"/>
                  <xsl:value-of select="string-join($this-map-value)"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="this-text-replacement" select="string-join($these-text-replacements)"/>
            <xsl:variable name="text-repl-len" select="string-length($this-text-replacement)"/>
            <xsl:variable name="this-is-empty" select="$text-repl-len lt 1"/>
            <xsl:variable name="ending-orig-pos"
               select="
                  if ($this-is-relevant) then
                     $orig-last-pos + count($these-txt-charpoints)
                  else
                     $orig-last-pos"
            />
            <xsl:variable name="ending-new-pos"
               select="
                  if ($this-is-relevant) then
                     $new-last-pos + $text-repl-len
                  else
                     $new-last-pos"
            />
            
            <xsl:choose>
               <!-- If the replacement is altogether empty, and this is the only witness, well, drop it. -->
               <xsl:when test="$this-is-relevant and $this-is-empty and count(tan:wit) eq 1"/>
               <xsl:when test="$this-is-relevant and $this-is-empty">
                  <!-- If it is being emptied out of this witness, demote the <c> to <u> (or keep it), and drop the <wit> -->
                  <u>
                     <xsl:copy-of select="tan:txt"/>
                     <xsl:copy-of select="tan:wit[not(@ref = $wit-id)]"/>
                  </u>
               </xsl:when>
               <xsl:when test="$this-is-relevant">
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <txt>
                        <xsl:value-of select="$this-text-replacement"/>
                     </txt>
                     <wit ref="{$wit-id}" pos="{$new-last-pos + 1}"/>
                     <xsl:copy-of select="tan:wit[not(@ref = $wit-id)]"/>
                  </xsl:copy>
                  
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
            
            <xsl:next-iteration>
               <xsl:with-param name="orig-last-pos" select="$ending-orig-pos"/>
               <xsl:with-param name="new-last-pos" select="$ending-new-pos"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:copy>
   </xsl:template>
   
   
   
   <!-- calculating the string position and length of each element in a tree -->
   
   <xsl:function name="tan:stamp-diff-with-text-data" as="item()*">
      <!-- 1-parameter version of tan:stamp-tree-with-text-data() -->
      <xsl:param name="diff-result" as="element(tan:diff)?"/>
      <xsl:variable name="out-pass-1"
         select="tan:stamp-tree-with-text-data($diff-result, false(), '^b$', (), 1)"/>
      <diff>
         <xsl:iterate select="$out-pass-1/*">
            <xsl:param name="next-pos" as="xs:integer" select="1"/>
            <xsl:variable name="this-length" select="(xs:integer(@_len), string-length(.))[1]"/>
            <xsl:variable name="new-pos"
               select="
                  if (self::tan:common or self::tan:b) then
                     ($next-pos + $this-length)
                  else
                     $next-pos"/>

            <xsl:choose>
               <xsl:when test="not(self::tan:b)">
                  <xsl:copy-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:attribute name="_pos" select="$next-pos"/>
                     <xsl:attribute name="_len" select="$this-length"/>
                     <xsl:copy-of select="node()"/>
                  </xsl:copy>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:next-iteration>
               <xsl:with-param name="next-pos" select="$new-pos"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </diff>
   </xsl:function>
   <xsl:template match="tan:b" mode="stamp-b-with-text-data">
      <xsl:variable name="prev-element" select="preceding-sibling::tan:common[1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="not(exists($prev-element))">
               <xsl:attribute name="_pos" select="1"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="_pos"
                  select="xs:integer($prev-element/@_pos) + xs:integer($prev-element/@_len)"/>
               <xsl:attribute name="_len" select="string-length(.)"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   
   <!--<xsl:function name="tan:stamp-collation-with-text-data" as="item()*">
      <!-\- Input: output from tan:collate(), a string -\->
      <!-\- Output: the collation results stamped with @_pos and @_len -\->
   </xsl:function>-->
   
   <xsl:function name="tan:stamp-class-1-tree-with-text-data" as="item()*">
      <!-- 2-parameter version for the main one below -->
      <!-- This version anticipates class 1 TAN-T(EI) files in their raw, resolved, or expanded state. It also includes 
      captures where the text has been replaced by tan:diff() output, but ignores <b>. -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:sequence select="tan:stamp-tree-with-text-data($tree-fragment, true(), (), '^(TAN-.+|TEI|text|body|div|common|a|(non-)?tok)$', 1)"/>
   </xsl:function>
   
   <xsl:function name="tan:stamp-tree-with-text-data" as="item()*">
      <!-- 2-parameter version for the main one below -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:param name="ignore-white-space" as="xs:boolean"/>
      <xsl:sequence select="tan:stamp-tree-with-text-data($tree-fragment, $ignore-white-space, (), (), 1)"/>
   </xsl:function>
   
   <xsl:function name="tan:stamp-tree-with-text-data" as="item()*">
      <!-- Input: any tree fragment; a boolean; an integer -->
      <!-- Output: the same tree fragment, but with @_pos stamped in every element specifying the position of the
      next enclosed text character, and @_len specifying the string length of the text. If the second parameter 
      is true, space-only text nodes will be ignored. The third parameter specifies the starting digit for the 
      next character. -->
      <!-- Input items will be treated as part of the same whole, not as separate items. If you wish to apply
      this function to several items independently, the function should be iterated upon. -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:param name="ignore-white-space" as="xs:boolean"/>
      <xsl:param name="exclude-from-count-elements-whose-names-match" as="xs:string?"/>
      <xsl:param name="exclude-from-count-elements-whose-names-do-not-match" as="xs:string?"/>
      <xsl:param name="next-char-number" as="xs:integer"/>
      <xsl:iterate select="$tree-fragment">
         <xsl:param name="next-char-pos" as="xs:integer" select="$next-char-number"/>
         <xsl:variable name="this-fragment" select="."/>
         <xsl:variable name="this-exception-fragment" as="element()*">
            <xsl:apply-templates select="$this-fragment" mode="filter-elements">
               <xsl:with-param name="keep-elements-whose-names-match" as="xs:string?" tunnel="yes" select="$exclude-from-count-elements-whose-names-match"/>
               <xsl:with-param name="keep-elements-whose-names-do-not-match" as="xs:string?" tunnel="yes" select="$exclude-from-count-elements-whose-names-do-not-match"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:variable name="this-fragment-text"
            select="
               if ($ignore-white-space) then
                  string-join($this-fragment/descendant-or-self::text()[matches(., '\S')])
               else
                  string($this-fragment)"
         />
         <xsl:variable name="this-exception-text"
            select="
               (if ($ignore-white-space) then
                  string-join($this-exception-fragment/descendant-or-self::text()[matches(., '\S')])
               else
                  string-join($this-exception-fragment))
               "
         />
         <xsl:variable name="this-fragment-length" select="string-length($this-fragment-text) - string-length($this-exception-text)"/>
         <xsl:apply-templates select="." mode="stamp-tree-with-text-data">
            <xsl:with-param name="ignore-white-space" select="$ignore-white-space" tunnel="yes"/>
            <xsl:with-param name="next-char-pos" select="$next-char-pos"/>
            <xsl:with-param name="current-node-length" select="$this-fragment-length"/>
            <xsl:with-param name="ignore-elements-whose-names-match" select="$exclude-from-count-elements-whose-names-match"/>
            <xsl:with-param name="ignore-elements-whose-names-do-not-match" select="$exclude-from-count-elements-whose-names-do-not-match"/>
         </xsl:apply-templates>
         <xsl:next-iteration>
            <xsl:with-param name="next-char-pos" select="$next-char-pos + $this-fragment-length"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>
   
   <xsl:template match="processing-instruction() | comment() | text()" mode="stamp-tree-with-text-data">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="document-node()" mode="stamp-tree-with-text-data">
      <xsl:param name="ignore-white-space" tunnel="yes" as="xs:boolean"/>
      <xsl:param name="next-char-pos" as="xs:integer"/>
      <xsl:param name="current-node-length" as="xs:integer"/>
      <xsl:param name="ignore-elements-whose-names-match" as="xs:string?"/>
      <xsl:param name="ignore-elements-whose-names-do-not-match" as="xs:string?"/>
      <xsl:document>
         <xsl:copy-of select="tan:stamp-tree-with-text-data(node(), $ignore-white-space, $ignore-elements-whose-names-match, $ignore-elements-whose-names-do-not-match, $next-char-pos)"/>
      </xsl:document>
   </xsl:template>
   <xsl:template match="*" mode="stamp-tree-with-text-data">
      <xsl:param name="ignore-white-space" tunnel="yes" as="xs:boolean"/>
      <xsl:param name="next-char-pos" as="xs:integer"/>
      <xsl:param name="current-node-length" as="xs:integer"/>
      <xsl:param name="ignore-elements-whose-names-match" as="xs:string?"/>
      <xsl:param name="ignore-elements-whose-names-do-not-match" as="xs:string?"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="ignore-this-element"
         select="
            if (string-length($ignore-elements-whose-names-match) gt 0) then
               matches($this-name, $ignore-elements-whose-names-match)
            else
               if (string-length($ignore-elements-whose-names-do-not-match) gt 0)
               then
                  (not(matches($this-name, $ignore-elements-whose-names-do-not-match)))
               else
                  false()"
      />
      <xsl:choose>
         <xsl:when test="$ignore-this-element">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="_pos" select="$next-char-pos"/>
               <xsl:attribute name="_len" select="$current-node-length"/>
               <xsl:copy-of
                  select="tan:stamp-tree-with-text-data(node(), $ignore-white-space, $ignore-elements-whose-names-match, $ignore-elements-whose-names-do-not-match, $next-char-pos)"
               />
            </xsl:copy>
            
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <!-- TEI-specific -->
   
   <xsl:function name="tan:normalize-tan-tei-divs" as="item()*">
      <!-- Input: tei tree(s); boolean -->
      <!-- Output: the same, but with leaf tei:divs space-normalized. If the 2nd parameter is true, any special 
            end-div characters will be removed -->
      <xsl:param name="input-tan-tei" as="item()*"/>
      <xsl:param name="remove-special-end-div-chars" as="xs:boolean"/>
      <xsl:apply-templates select="$input-tan-tei" mode="normalize-tan-tei-divs">
         <xsl:with-param name="remove-special-end-div-chars" select="$remove-special-end-div-chars" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:template match="tei:div[not(tei:div)]" mode="normalize-tan-tei-divs">
      <xsl:param name="remove-special-end-div-chars" tunnel="yes" as="xs:boolean"/>
      <xsl:variable name="this-tree-as-sequence" as="element()">
         <sequence>
            <xsl:copy-of select="tan:tree-to-sequence(.)"/>
         </sequence>
      </xsl:variable>
      <xsl:variable name="output-pass-1" as="element()">
         <output>
            <xsl:iterate select="$this-tree-as-sequence/node()">
               <xsl:choose>
                  <xsl:when test=". instance of text()">
                     <!-- If it is a blank text node, put only one space marker, for the end. -->
                     <xsl:if test="matches(., '^\s+\S')">
                        <_space/>
                     </xsl:if>
                     <xsl:value-of select="normalize-space(.)"/>
                     <xsl:if test="matches(., '\s$')">
                        <_space/>
                     </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="."/>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:next-iteration/>
            </xsl:iterate>
         </output>
      </xsl:variable>
      <xsl:variable name="last-text-node" select="$output-pass-1/text()[last()]"/>
      <xsl:variable name="output-pass-2" as="element()">
         <output>
            <xsl:iterate select="$output-pass-1/node()">
               <xsl:param name="last-text-ended-in-space" as="xs:boolean" select="true()"/>

               <xsl:variable name="this-is-last-text-node" as="xs:boolean"
                  select=". is $last-text-node"/>
               <xsl:variable name="this-ends-with-special-char"
                  select="matches(., $special-end-div-chars-regex)"/>
               <xsl:variable name="current-text-ends-in-space" as="xs:boolean">
                  <xsl:choose>
                     <xsl:when test="self::tan:_space">
                        <xsl:sequence select="true()"/>
                     </xsl:when>
                     <xsl:when test="$this-is-last-text-node and not($this-ends-with-special-char)">
                        <xsl:sequence select="true()"/>
                     </xsl:when>
                     <xsl:when test="self::text()">
                        <xsl:sequence select="false()"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$last-text-ended-in-space"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               
               <xsl:variable name="diagnostics-on" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'This item: ' || serialize(.)"/>
                  <xsl:message select="'Last text ended in space? ', $last-text-ended-in-space"/>
                  <xsl:message select="'This is last text node? ', $this-is-last-text-node"/>
                  <xsl:message select="'Supplied last text node: ' || $last-text-node"/>
                  <xsl:message select="'This ends in special char? ', $this-ends-with-special-char"/>
                  <xsl:message select="'Current text ends in space? ', $current-text-ends-in-space"/>
               </xsl:if>

               <!-- output -->
               <xsl:choose>
                  <xsl:when test="self::tan:_space and $last-text-ended-in-space"/>
                  <xsl:when test="self::tan:_space and not($last-text-ended-in-space)">
                     <xsl:value-of select="' '"/>
                  </xsl:when>
                  <xsl:when
                     test="
                        $this-is-last-text-node and $this-ends-with-special-char
                        and $remove-special-end-div-chars">
                     <xsl:value-of select="replace(., $special-end-div-chars-regex || '$', '')"/>
                  </xsl:when>
                  <xsl:when test="$this-is-last-text-node and $this-ends-with-special-char">
                     <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:when test="$this-is-last-text-node">
                     <xsl:value-of select=". || ' '"/>
                  </xsl:when>
                  <xsl:when test="self::text()">
                     <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="."/>
                  </xsl:otherwise>
               </xsl:choose>

               <xsl:next-iteration>
                  <xsl:with-param name="last-text-ended-in-space" select="$current-text-ends-in-space"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </output>
      </xsl:variable>
      <xsl:variable name="output-pass-3" select="tan:sequence-to-tree($output-pass-2/node())"/>

      <!--<xsl:copy>
            <xsl:copy-of select="@*"/>
            <test-tree-as-seq><xsl:copy-of select="$this-tree-as-sequence"/></test-tree-as-seq>
            <test-out-1><xsl:copy-of select="$output-pass-1"/></test-out-1>
            <test-out-2><xsl:copy-of select="$output-pass-2"/></test-out-2>
            <test-out-3><xsl:copy-of select="$output-pass-3"/></test-out-3>
        </xsl:copy>-->
      <xsl:copy-of select="$output-pass-3"/>
   </xsl:template>
   


   <!-- Functions: sequences-->

   <xsl:function name="tan:most-common-item" as="item()?">
      <!-- Input: any sequence of items -->
      <!-- Output: the one item that appears most frequently -->
      <!-- If two or more items appear equally frequently, only the first is returned -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:for-each-group select="$sequence" group-by=".">
         <xsl:sort select="count(current-group())" order="descending"/>
         <xsl:if test="position() = 1">
            <xsl:copy-of select="current-group()[1]"/>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>
   
   <xsl:function name="tan:integers-to-sequence" as="xs:string?">
      <!-- Input: any integers -->
      <!-- Output: a string that compactly expresses those integers -->
      <!-- Example: (1, 3, 6, 1, 2) - > "1-3, 6" -->
      <xsl:param name="input-integers" as="xs:integer*"/>
      <xsl:variable name="input-sorted" as="element()">
         <sorted>
            <xsl:for-each select="distinct-values($input-integers)">
               <xsl:sort/>
               <n>
                  <xsl:value-of select="."/>
               </n>
            </xsl:for-each>
         </sorted>
      </xsl:variable>
      <xsl:variable name="input-analyzed" as="element()">
         <xsl:apply-templates select="$input-sorted" mode="integers-to-sequence"/>
      </xsl:variable>
      <xsl:variable name="output-atoms" as="xs:string*">
         <xsl:for-each-group select="$input-analyzed/*" group-starting-with="*[@start]">
            <xsl:variable name="last-item" select="current-group()[not(@start)][last()]"/>
            <xsl:choose>
               <xsl:when test="exists($last-item)">
                  <xsl:value-of select="concat(current-group()[1], '-', $last-item)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="current-group()[1]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:variable>
      <!--<xsl:message select="$input-analyzed"/>-->
      <!--<xsl:value-of select="$input-sorted"/>-->
      <!--<xsl:value-of select="$input-analyzed"/>-->
      <!--<xsl:value-of select="$output-atoms"/>-->
      <xsl:value-of select="string-join($output-atoms, ', ')"/>
   </xsl:function>
   <xsl:template match="tan:n" mode="integers-to-sequence">
      <xsl:variable name="preceding-n" select="preceding-sibling::tan:n[1]"/>
      <xsl:variable name="this-n-val" select="xs:integer(.)"/>
      <xsl:variable name="preceding-n-val" select="xs:integer($preceding-n)"/>
      <xsl:copy>
         <xsl:choose>
            <xsl:when test="not(exists($preceding-n-val))">
               <xsl:attribute name="start"/>
            </xsl:when>
            <xsl:when test="$this-n-val - $preceding-n-val gt 1">
               <xsl:attribute name="start"/>
            </xsl:when>
         </xsl:choose>
         <xsl:value-of select="."/>
      </xsl:copy>
   </xsl:template>


   <!-- Functions: accessors and manipulation of uris -->
   
   <xsl:function name="tan:open-file">
      <!-- 1-parameter function of the main one below -->
      <xsl:param name="resolved-urls"/>
      <xsl:copy-of select="tan:open-file($resolved-urls, $fallback-encoding)"/>
   </xsl:function>
   
   <xsl:function name="tan:open-file" as="document-node()*">
      <!-- Input: items that can be resolved as strings; a string -->
      <!-- Output: for each resolvable string in the first parameter, if a document is available, the document; 
            if it is not, but unparsed text is available, a document with the unparsed text wrapped in a root 
            element; otherwise an empty document node. If unparsed text is not available, another attempt 
            will be made on a fallback encoding specified by the 2nd parameter.
        -->
      <!-- If the file is not an XML document, the content will be wrapped by a root element of an
        XML document. That root node will have @xml:base pointing to the source url. -->
      <xsl:param name="resolved-urls"/>
      <xsl:param name="target-fallback-encoding" as="xs:string*"/>

      <xsl:for-each select="$resolved-urls[. castable as xs:string]">
         <xsl:variable name="this-path-normalized" select="replace(xs:string(.), '\s', '%20')"/>
         <xsl:variable name="this-path-normalized-for-extension-functions"
            select="replace($this-path-normalized, 'file:', '')"/>
         <xsl:choose>
            <xsl:when test="doc-available($this-path-normalized)">
               <xsl:sequence select="doc($this-path-normalized)"/>
            </xsl:when>
            <xsl:when test="unparsed-text-available($this-path-normalized)">
               <xsl:document>
                  <unparsed-text>
                     <xsl:attribute name="xml:base" select="$this-path-normalized"/>
                     <xsl:value-of select="unparsed-text($this-path-normalized)"/>
                  </unparsed-text>
               </xsl:document>
            </xsl:when>
            <xsl:when
               test="unparsed-text-available($this-path-normalized, $target-fallback-encoding)">
               <xsl:document>
                  <unparsed-text>
                     <xsl:attribute name="xml:base" select="$this-path-normalized"/>
                     <xsl:value-of
                        select="unparsed-text($this-path-normalized, $target-fallback-encoding)"/>
                  </unparsed-text>
               </xsl:document>
            </xsl:when>
            <xsl:when test="true()" use-when="$advanced-saxon-features-available">
               <xsl:variable name="file-exists" use-when="$advanced-saxon-features-available"
                  as="xs:boolean?">
                  <xsl:try select="file:exists($this-path-normalized-for-extension-functions)">
                     <xsl:catch>
                        <xsl:message
                           select="$this-path-normalized-for-extension-functions || ' breaks the syntax allowed for the function file:exists()'"/>
                        <xsl:value-of select="false()"/>
                     </xsl:catch>
                  </xsl:try>
               </xsl:variable>
               <xsl:if test="$file-exists">
                  <xsl:variable name="binary-file"
                     select="file:read-binary($this-path-normalized-for-extension-functions)"/>
                  <xsl:message
                     select="$this-path-normalized-for-extension-functions || ' points to a file that exists, but is neither XML nor unparsed text (UTF-8 or fallback encoding ' || $target-fallback-encoding || '). Returning an XML document whose root element contains a single text node encoded as xs:base64Binary.'"/>
                  <xsl:document>
                     <base64Binary>
                        <xsl:attribute name="xml:base"
                           select="$this-path-normalized-for-extension-functions"/>
                        <xsl:value-of select="$binary-file"/>
                     </base64Binary>
                  </xsl:document>
               </xsl:if>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message
                  select="$this-path-normalized || ' points to a file that does not exist. Returning an empty document node.'"/>
               <xsl:document/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:zip-uris" as="xs:anyURI*">
      <!-- Input: any string representing a uri -->
      <!-- Output: the same string with 'zip:' prepended if it represents a uri to a file in an archive (docx, jar, zip, etc.) -->
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:for-each select="$uris">
         <xsl:value-of
            select="
               if (matches(., '!/')) then
                  concat('zip:', .)
               else
                  ."
         />
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:revise-hrefs" as="item()*">
      <!-- Input: an item that should have urls resolved; the original url of the item; the target url (the item's destination) -->
      <!-- Output: the item with each @href (including those in processing instructions) and html:*/@src resolved -->
      <xsl:param name="item-to-resolve" as="item()?"/>
      <xsl:param name="items-original-url" as="xs:string"/>
      <xsl:param name="items-destination-url" as="xs:string"/>
      <xsl:variable name="original-url-resolved" select="resolve-uri($items-original-url)"/>
      <xsl:variable name="destination-url-resolved" select="resolve-uri($items-destination-url)"/>
      <xsl:if test="not($items-original-url = $original-url-resolved)">
         <xsl:message select="'tan:revise-hrefs() warning: param 2 url, ', $items-original-url, ', does not match resolved state: ', $original-url-resolved"/>
      </xsl:if>
      <xsl:if test="not($items-destination-url = $destination-url-resolved) and not(not($items-original-url = $original-url-resolved))">
         <xsl:message select="'tan:revise-hrefs() warning: param 3 url, ', $items-destination-url, ', does not match resolved state: ', $destination-url-resolved"/>
      </xsl:if>
      <xsl:apply-templates select="$item-to-resolve" mode="revise-hrefs">
         <xsl:with-param name="original-url" select="$items-original-url" tunnel="yes"/>
         <xsl:with-param name="target-url" select="$items-destination-url" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="node() | @*" mode="revise-hrefs">
      <xsl:copy>
         <xsl:apply-templates select="node() | @*" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="processing-instruction()" priority="1" mode="revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" required="yes"/>
      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:processing-instruction name="{name(.)}">
            <xsl:analyze-string select="." regex="{$href-regex}">
                <xsl:matching-substring>
                    <xsl:value-of select="concat(regex-group(1), tan:uri-relative-to(resolve-uri(regex-group(2), $original-url), $target-url), regex-group(3))"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:processing-instruction>
   </xsl:template>
   <xsl:template match="@href" mode="revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" required="yes"/>
      <xsl:variable name="this-href-resolved" select="resolve-uri(., $original-url)"/>
      <xsl:variable name="this-href-relative"
         select="tan:uri-relative-to($this-href-resolved, $target-url)"/>
      <xsl:choose>
         <xsl:when test="matches(., '^#')">
            <xsl:copy/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:attribute name="href" select="$this-href-relative"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="html:script/@src" mode="revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" required="yes"/>
      <xsl:attribute name="src"
         select="tan:uri-relative-to(resolve-uri(., $original-url), $target-url)"/>
   </xsl:template>


   <!-- Functions: XPath Functions and Operators -->

   <xsl:function name="tan:evaluate" as="item()*">
      <!-- 2-param version of the fuller one below -->
      <xsl:param name="string-with-xpath-to-evaluate" as="xs:string"/>
      <xsl:param name="context-1" as="item()*"/>
      <xsl:copy-of select="tan:evaluate($string-with-xpath-to-evaluate, $context-1, ())"/>
   </xsl:function>
   <xsl:function name="tan:evaluate" as="item()*">
      <!-- Input: a string to be evaluated in light of XPath expressions; a context node -->
      <!-- Output: the result of the string evaluated as an XPath statement against the context node -->
      <xsl:param name="string-with-xpath-to-evaluate" as="xs:string"/>
      <xsl:param name="context-1" as="item()*"/>
      <xsl:param name="context-2" as="item()*"/>
      <xsl:if test="string-length($string-with-xpath-to-evaluate) gt 0">
         <xsl:variable name="results" as="item()*">
            <xsl:analyze-string select="$string-with-xpath-to-evaluate" regex="{$xpath-pattern}">
               <xsl:matching-substring>
                  <xsl:variable name="this-xpath" select="replace(., '[\{\}]', '')"/>
                  <xsl:choose>
                     <xsl:when test="true()" use-when="$saxon-extension-functions-available">
                        <!-- If saxon:evaluate is available, use it -->
                        <xsl:copy-of select="saxon:evaluate($this-xpath, $context-1, $context-2)"
                           copy-namespaces="no"/>
                        
                     </xsl:when>
                     
                     <xsl:when test="$this-xpath = 'name($p1)'">
                        <xsl:value-of select="name($context-1)"/>
                     </xsl:when>
                     <xsl:when test="matches($this-xpath, '^$p1/@')">
                        <xsl:value-of select="$context-1/@*[name() = replace(., '^\$@', '')]"
                        />
                     </xsl:when>
                     <xsl:when test="matches($this-xpath, '^$p1/\w+$')">
                        <xsl:value-of select="$context-1/*[name() = $this-xpath]"/>
                     </xsl:when>
                     <xsl:when test="matches($this-xpath, '^$p1/\w+\[\d+\]$')">
                        <xsl:variable name="simple-xpath-analyzed" as="xs:string*">
                           <xsl:analyze-string select="$this-xpath" regex="\[\d+\]$">
                              <xsl:matching-substring>
                                 <xsl:value-of select="replace(., '\$p|\D', '')"/>
                              </xsl:matching-substring>
                              <xsl:non-matching-substring>
                                 <xsl:value-of select="."/>
                              </xsl:non-matching-substring>
                           </xsl:analyze-string>
                        </xsl:variable>
                        <xsl:value-of
                           select="$context-1/*[name() = $simple-xpath-analyzed[1]][$simple-xpath-analyzed[2]]"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:message>
                           <xsl:value-of
                              select="concat('saxon:evaluate unavailable, and no actions predefined for string: ', .)"
                           />
                        </xsl:message>
                        <xsl:value-of select="."/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:for-each-group select="$results" group-adjacent=". instance of xs:string">
            <xsl:choose>
               <xsl:when test="current-grouping-key() = true()">
                  <xsl:value-of select="string-join(current-group(), '')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:if>
   </xsl:function>


   <!-- FUNCTIONS: TAN FILES -->
   <!-- General TAN files -->

   <xsl:variable name="orig-self-validated" as="document-node()">
      <xsl:apply-templates select="$orig-self" mode="imitate-validation"/>
   </xsl:variable>
   <xsl:template match="*" mode="imitate-validation">
      <!-- new stuff -->
      <xsl:variable name="these-q-refs"
         select="
            for $i in ancestor-or-self::*
            return
               (generate-id($i))"
      />
      
      <!-- This template imitates the process of validation, for testing on efficiency, etc. -->
      <xsl:variable name="this-q-ref" select="generate-id(.)"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="this-checked-for-errors"
         select="tan:get-via-q-ref($this-q-ref, $self-expanded[1])"/>
      <xsl:variable name="has-include-or-which-attr" select="exists(@include) or exists(@which)"/>
      <xsl:variable name="relevant-fatalities"
         select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:fatal[not(@xml:id = $errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:fatal[not(@xml:id = $errors-to-squelch)]"/>
      <xsl:variable name="relevant-errors"
         select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:error[not(@xml:id = $errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:error[not(@xml:id = $errors-to-squelch)]"/>
      <xsl:variable name="relevant-warnings"
         select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:warning[not(@xml:id = $errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:warning[not(@xml:id = $errors-to-squelch)]"
      />
      <xsl:variable name="relevant-info"
         select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:info
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:info"/>
      <xsl:variable name="help-offered"
         select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:help
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:help"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($relevant-fatalities)">
            <sch>
               <value-of select="tan:error-report($relevant-fatalities)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-errors)">
            <sch>
               <value-of select="tan:error-report($relevant-errors)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-warnings)">
            <sch>
               <value-of select="tan:error-report($relevant-warnings)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-info)">
            <sch>
               <value-of select="$relevant-info/tan:message"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($help-offered)">
            <sch>
               <value-of select="$help-offered/tan:message"/>
            </sch>
         </xsl:if>
         <xsl:if test="not(exists($this-checked-for-errors))">
            <sch><value-of select="$this-q-ref"/> doesn't match; other @q values of <value-of
                  select="$this-name"/>: <value-of
                  select="string-join($self-expanded//*[name() = $this-name]/@q, ', ')"/></sch>
         </xsl:if>

         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
   
   <!--<xsl:variable name="error-tests" as="document-node()*"
      select="doc('errors/error-test-1.tan-t.xml'), doc('errors/error-test-2.tan-voc.xml')"/>-->
   <xsl:variable name="error-tests" as="document-node()*"
      select="collection('errors/?select=error-test-*.xml')"/>
   <xsl:variable name="error-markers" select="$error-tests//comment()[matches(., '\w\w\w\d\d')]"/>

   <!-- Functions: TAN-T(EI) -->

   <xsl:function name="tan:reset-hierarchy" as="document-node()*">
      <!-- Input: any expanded class-1 documents whose <div>s may be in the wrong place, because <rename> or <reassign> have altered the <ref> values; a boolean indicating whether misplaced leaf divs should be flagged -->
      <!-- Output: the same documents, with <div>s restored to their proper place in the hierarchy -->
      <xsl:param name="expanded-class-1-docs" as="document-node()*"/>
      <xsl:param name="flag-misplaced-leaf-divs" as="xs:boolean?"/>
      <xsl:apply-templates select="$expanded-class-1-docs" mode="reset-hierarchy">
         <xsl:with-param name="flag-misplaced-leaf-divs" select="$flag-misplaced-leaf-divs"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:function name="tan:normalize-xml-element-space" as="element()?">
      <!-- Input: an element -->
      <!-- Output: the same element, but with text node descendants space-normalized -->
      <!-- If a text node begins with a space, and its first preceding sibling text node ends with a space, then the preceding space is dropped, otherwise it is normalized to a single space -->
      <xsl:param name="element-to-normalize" as="element()?"/>
      <xsl:apply-templates select="$element-to-normalize" mode="normalize-xml-fragment-space"/>
   </xsl:function>
   <xsl:template match="text()" mode="normalize-xml-fragment-space">
      <xsl:variable name="prev-sibling-text" select="preceding-sibling::text()[1]"/>
      <xsl:variable name="last-text-node"
         select="
            if (exists($prev-sibling-text)) then
               $prev-sibling-text
            else
               (preceding::text())[last()]"/>
      <xsl:analyze-string select="." regex="^(\s+)">
         <xsl:matching-substring>
            <xsl:choose>
               <xsl:when test="matches($last-text-node, '\S$')">
                  <xsl:text> </xsl:text>
               </xsl:when>
            </xsl:choose>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <xsl:analyze-string select="." regex="\s+$">
               <xsl:matching-substring>
                  <xsl:text> </xsl:text>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="normalize-space(.)"/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
   </xsl:template>

   <!-- Functions: TAN-A-lm -->

   <xsl:function name="tan:lm-data" as="element()*">
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
            <xsl:for-each
               select="
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
      <xsl:variable name="lex-val-matches"
         select="
            for $i in $these-tan-a-lm-files
            return
               key('get-ana', $token-value, $i)"/>

      <!-- If there's no exact match, look for a near match -->
      <xsl:variable name="this-string-approx" select="tan:string-base($token-value)"/>
      <xsl:variable name="lex-rgx-and-approx-matches"
         select="
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
   
   <xsl:function name="tan:replace-expanded-class-1-body" as="document-node()?">
      <!-- Input: An expanded class-1 file; a string -->
      <!-- Output: the class-1 file, but with the body text replaced with the string, allocated according to tan:diff() -->
      <xsl:param name="expanded-class-1-file" as="document-node()?"/>
      <xsl:param name="new-body-text" as="xs:string?"/>
      <xsl:variable name="current-text"
         select="string-join($expanded-class-1-file/tan:TAN-T/tan:body//tan:div[not(tan:div)]/(text() | tan:tok | tan:non-tok))"
      />
      <xsl:variable name="text-diff" select="tan:diff($current-text, $new-body-text, false())"/>
      <xsl:variable name="text-diff-map" select="tan:diff-a-map($text-diff)"/>
      
      <xsl:variable name="input-file-marked" select="tan:stamp-class-1-tree-with-text-data($expanded-class-1-file)" as="document-node()?"/>
      
      <xsl:variable name="output-pass-1" as="document-node()?">
         <xsl:apply-templates select="$input-file-marked" mode="replace-expanded-class-1">
            <xsl:with-param name="div-diff-map" tunnel="yes" select="$text-diff-map"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      
      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Output for tan:replace-expanded-class-1-body() being replaced by diagnostic output.'"/>
            <xsl:document>
               <diagnostics>
                  <current-text><xsl:value-of select="$current-text"/></current-text>
                  <new-body-text><xsl:value-of select="$new-body-text"/></new-body-text>
                  <text-diff><xsl:copy-of select="$text-diff"/></text-diff>
                  <wit2-to-wit-map><xsl:value-of select="map:for-each($text-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></wit2-to-wit-map>
                  <input-file-marked><xsl:copy-of select="$input-file-marked"/></input-file-marked>
                  <output-pass-1><xsl:copy-of select="$output-pass-1"/></output-pass-1>
               </diagnostics>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$output-pass-1"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:template match="*[@_pos]" mode="replace-expanded-class-1">
      <xsl:copy>
         <xsl:copy-of select="@* except (@_pos | @_len)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[not(tan:div)]" priority="1" mode="replace-expanded-class-1">
      <xsl:param name="div-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:variable name="this-map-value" as="item()*"
         select="
            for $i in ($this-start to $this-end)
            return
               map:get($div-diff-map, $i)"
      />
      <xsl:copy>
         <xsl:copy-of select="@* except (@_pos | @_len)"/>
         <xsl:copy-of select="node() except (text() | tan:tok | tan:non-tok)"/>
         <xsl:value-of select="string-join($this-map-value)"/>
      </xsl:copy>
      
   </xsl:template>
   

   <!-- BIBLIOGRAPHIES -->
   <xsl:param name="bibliography-words-to-ignore" as="xs:string*"
      select="('university', 'press', 'publication')"/>
   <xsl:function name="tan:possible-bibliography-id" as="xs:string">
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
            <xsl:if test="not(lower-case(.) = $bibliography-words-to-ignore)">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of
         select="string-join(distinct-values(($this-citation-longest-words[position() lt 3], $this-citation-dates[1])), ' ')"
      />
   </xsl:function>

</xsl:stylesheet>
