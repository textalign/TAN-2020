<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:file="http://expath.org/ns/file"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet allows users to quickly test a TAN file or components of the TAN library. Alter as you like. -->
   
   <xsl:param name="tan:validation-mode-on" static="yes" select="false()"/>
   <xsl:param name="tan:distribute-vocabulary" select="false()"/>
   
   <!--<xsl:import href="../../TAN-2020/functions/TAN-A-functions.xsl"/>-->
   <!--<xsl:import href="../../TAN-2020/functions/TAN-extra-functions.xsl"/>-->
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   <xsl:include href="test%20TAN%20function%20library%20previous.xsl"/>

   <xsl:output method="xml" indent="yes"/>
   
   <xsl:param name="tan:change-message">Assorted tests on the TAN Function Library</xsl:param>
   <xsl:param name="tan:stylesheet-iri">tag:textalign.net,2015:algorithm:tan-library-test</xsl:param>
   <xsl:param name="tan:stylesheet-url" as="xs:string" select="static-base-uri()"/>
   
   <xsl:param name="tan:default-validation-phase">terse</xsl:param>
   
   
   <xsl:template match="/">
      <xsl:variable name="values" select="(1,2,3,4,5)" as="xs:double+"/>
      <test-common>
         <self-resolved><xsl:copy-of select="$tan:self-resolved"/></self-resolved>
         <!--<self-expanded count="{count($tan:self-expanded)}"><xsl:copy-of select="$tan:self-expanded"/></self-expanded>-->
         <!--<vocabularies-resolved><xsl:copy-of select="$tan:vocabularies-resolved"/></vocabularies-resolved>-->
         <!--<source-docs><xsl:copy-of select="tan:get-1st-doc($tan:head/tan:source)"/></source-docs>-->
         <!--<sources-resolved-plus><xsl:copy-of select="tan:get-and-resolve-dependency($tan:self-resolved/*/tan:head/tan:source)"/></sources-resolved-plus>-->
         <!--<sources-resolved count="{count($tan:sources-resolved)}"><xsl:copy-of select="tan:shallow-copy($tan:sources-resolved/*)"/></sources-resolved>-->
         <!--<redivisions-resolved count="{count($tan:redivisions-resolved)}"><xsl:copy-of select="$tan:redivisions-resolved"/></redivisions-resolved>-->
         <!--<model><xsl:copy-of select="$tan:model-resolved"/></model>-->
         
      </test-common>
      
      
   </xsl:template>
   
</xsl:stylesheet>
