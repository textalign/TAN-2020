<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet allows users to quickly test a TAN file or components of the TAN library. Alter as you like. -->
   
   <xsl:param name="tan:validation-mode-on" static="yes" select="false()"/>
   
   <!--<xsl:include href="../../functions/TAN-A-functions.xsl"/>-->
   <!--<xsl:include href="../../functions/TAN-extra-functions.xsl"/>-->
   <xsl:include href="../functions-2/TAN-function-library.xsl"/>

   <xsl:output method="xml" indent="yes"/>
   
   <xsl:param name="tan:change-message">Assorted tests on the TAN Function Library</xsl:param>
   <xsl:param name="tan:stylesheet-iri">tag:textalign.net,2015:algorithm:tan-library-test</xsl:param>
   <xsl:param name="tan:stylesheet-url" as="xs:string" select="static-base-uri()"/>
   
   <xsl:variable name="test-el" as="element()">
      <normalization which="no hyphens"/>
   </xsl:variable>
   
   <xsl:param name="tan:default-validation-phase">terse</xsl:param>
   
   <xsl:variable name="this-model-expanded" select="tan:expand-doc($tan:model-resolved, 'terse', false())"/>
   
   <xsl:variable name="test-tree" as="document-node()" select="doc('test.xml')"/>
   <xsl:variable name="test-tree-seq" select="tan:tree-to-sequence($test-tree)" as="item()*"/>
   <xsl:variable name="test-tree-restored" select="tan:sequence-to-tree($test-tree-seq)" as="item()*"/>
   
   <xsl:variable name="ns-nodes" as="element()*">
      <xsl:apply-templates mode="tan:build-namespace-map"/>
   </xsl:variable>
   
   
   <xsl:function name="tan:integer-clusters" as="xs:integer*">
      <!-- Input: two sequences of integers -->
      <!-- Output: all of the integers from the second parameter, as well as all integers from the first that
            form a chain of one or more consecutive integers from any member of the second sequence. Output will
            be sorted in ascending order. -->
      <!-- Example: (1, 4, 5, 7, 9) and (6, 12) - > (4, 5, 6, 7, 12) -->
      <!-- This function was written to differentiate between aura points of interest and those not of interest,
            given the insertion of new aura points. -->
      <xsl:param name="integers-to-filter" as="xs:integer*"/>
      <xsl:param name="cluster-cores" as="xs:integer*"/>
      
      <xsl:variable name="seq-start" as="xs:integer?" select="min(($integers-to-filter, $cluster-cores))"/>
      <xsl:variable name="seq-end" as="xs:integer?" select="max(($integers-to-filter, $cluster-cores))"/>
      <xsl:variable name="false-int" as="xs:integer?" select="$seq-start - 1"/>
      <xsl:variable name="new-sequence" as="xs:integer*" select="
            for $i in ($seq-start to $seq-end)
            return
               (if ($i = ($integers-to-filter, $cluster-cores)) then
                  $i
               else
                  $false-int)"/>
      
      <xsl:for-each-group select="$new-sequence" group-adjacent=". gt $false-int">
         <xsl:if test="current-grouping-key() and (current-group() = $cluster-cores)">
            <xsl:sequence select="current-group()"/>
         </xsl:if>
      </xsl:for-each-group>
      
   </xsl:function>
   
   <xsl:variable name="string-a" as="xs:string">Classical models of string comparison have been difficult to implement in XSLT, in part because MATCH THEM those models are designed for imperative, stateful programming. In this article I introduce a new XSLT function, ns:diff(), which is built upon a different approach to string comparison, one more conducive to a declarative, stateless language. ns:diff() is efficient and fast, even on pairs of very long strings (100K to 1M characters), in part because of its staggered-sample approach, in part because of its optimization stategy for long strings. Its results are optimal, as the THEM POTATOES function normally returns a minimal diff, or shortest edit script.</xsl:variable>
   <xsl:variable name="string-b" as="xs:string">Classical models of string comparison have been difficult to implement in XSLT, in part because those models are designed for imperative, stateful programming. In this article I introduce a new XSLT function, ns:diff(), which is built upon a different approach to string comparison, one more conducive to a declarative, stateless language. ns:diff() is efficient and fast, even MATxCH THEM POTATOxES on pairs of very long strings (100K to 1M characters), in part because of its staggered-sample approach, in part because of its optimization stategy for long strings. Its results are optimal, as the function normally returns a minimal diff, or shortest edit script.</xsl:variable>
   <xsl:variable name="str-diff" as="element()" select="tan:diff($string-a, $string-b, false())"/>
   
   
   

   <xsl:template match="/">
      <xsl:variable name="values" select="(1,2,3,4,5)" as="xs:double+"/>
      
      <test>
         <xsl:copy-of select="tan:get-diff-output-transpositions($str-diff, 5, 0.8)"/>
         <!--<xsl:copy-of select="tan:stamp-tree-with-text-data(tan:stamp-diff-with-text-data($str-diff), true())"/>-->
         <!--<xsl:copy-of select="tan:stamp-tree-with-text-data($str-diff, false())"/>-->
         <!--<slices>
            <xsl:copy-of select="tan:map-to-xml(tan:get-diff-output-slices($str-diff, 5, 0.8, 0, true()))"/>
         </slices>-->
         <!--<int-cl>
            <xsl:copy-of select="tan:integer-clusters((1, 4, 5, 7, 9), (6, 12))"/>
         </int-cl>-->
         <!--<xsl:for-each select="1 to count($values)">
            <xsl:sequence select="$values[current()]"/>    
         </xsl:for-each>-->
         <!--<s2-test><xsl:copy-of select="tan:resolve-doc(tan:get-1st-doc($tan:head/tan:source[2]), true(), tan:attr('src', ($tan:head/tan:source[2]/@xml:id, '1')[1]))"/></s2-test>-->
         <!--<xsl:copy-of select="tan:normalize-tree-space($tan:sources-resolved, true())"/>-->
         <!--<xsl:for-each select="$tan:self-expanded">
            <xsl:value-of select="tan:node-type(.)"/>
         </xsl:for-each>-->
         <!--<collate><xsl:sequence select="tan:collate(('abc', 'bcd', 'cde'), (), true())"></xsl:sequence></collate>-->
         <!--<card><xsl:sequence select="tan:cardinal(2001)"/></card>-->
         <!--<cfne><xsl:sequence select="tan:cfn('jar:file:/E:/Joel/Dropbox/TAN/library-arithmeticus/test/ring1951rev')"></xsl:sequence></cfne>-->
         <!--<uri-test><xsl:copy-of select="tan:uri-relative-to('file:/e:/COVID-19-analysis-tables/temperature.html', 'file:/e:/COVID-19-analysis-tables/test3.xml')"/></uri-test>-->
         <!--<ns-nodes><xsl:copy-of select="$ns-nodes"/></ns-nodes>-->
         <!--<namespace-test><xsl:copy-of select="//namespace-node()"/></namespace-test>-->
         <!--<html-test><xsl:copy-of select="tan:convert-to-html(/, true())"/></html-test>-->
         <!--<tree-to-seq><xsl:sequence select="$test-tree-seq"/></tree-to-seq>-->
         <!--<seq-to-tree><xsl:copy-of select="$test-tree-restored"/></seq-to-tree>-->
         <!--<self-resolved><xsl:copy-of select="$tan:self-resolved"/></self-resolved>-->
         <!--<sources-resolved count="{count($tan:sources-resolved)}"><xsl:copy-of select="$tan:sources-resolved"/></sources-resolved>-->
         <!--<self-expanded count="{count($tan:self-expanded)}"><xsl:copy-of select="$tan:self-expanded"/></self-expanded>-->
         
         <!--<model-res><xsl:copy-of select="$tan:model-resolved"/></model-res>-->
         <!--<href><xsl:copy-of select="tan:revise-hrefs(/, 'http://www.w3.org/2001/XMLSchema', 'http://www.w3.org/2001/XMLSchema2')"/></href>-->
         <!--<targ-el-names><xsl:copy-of select="tan:target-element-names($test-el/@which)"/></targ-el-names>-->
         <!--<voc-test><xsl:copy-of select="tan:vocabulary('normalization', 'no hyphens', $tan:head)"/></voc-test>-->
         <!--<el-attr-wh><xsl:copy-of select="string-join($TAN-elements-that-take-the-attribute-which/@name, ', ')"/></el-attr-wh>-->
         <!--<shallow-copy><xsl:copy-of select="tan:shallow-copy(/*/*[1], 2)"/></shallow-copy>-->
         <!--<TAN-vocabularies><xsl:copy-of select="$tan:TAN-vocabularies"/></TAN-vocabularies>-->
         <!--<vocab><xsl:copy-of select="$tan:all-vocabularies"/></vocab>-->
         <!--<cat><xsl:copy-of select="tan:catalogs(/, true())"/></cat>-->
         <!--<merged-docs>
            <xsl:copy-of select="tan:merge-expanded-docs(($tan:self-expanded, tan:expand-doc($tan:model-resolved, 'terse')))"/>
         </merged-docs>-->
      </test>
      <!--<xsl:result-document format="xml" href="../output/{tan:cfn(/)}-diagnostics.xml">
         <diagnostics>
            <!-\-<sources-resolved count="{count($tan:sources-resolved)}"><xsl:copy-of select="$tan:sources-resolved[2]"/></sources-resolved>-\->
            <!-\-<source-norm><xsl:copy-of select="tan:normalize-tree-space($tan:sources-resolved[2], true())"/></source-norm>-\->
            <self-expanded count="{count($tan:self-expanded)}"><xsl:copy-of select="$tan:self-expanded[3]"/></self-expanded>
         </diagnostics>
      </xsl:result-document>-->
   </xsl:template>
   
</xsl:stylesheet>
