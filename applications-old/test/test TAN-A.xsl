<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet allows users to quickly test a TAN file or components of the TAN library. Alter as you like. -->

   <xsl:include href="../../functions/TAN-A-functions.xsl"/>
   <xsl:include href="../../functions/TAN-extra-functions.xsl"/>
   <xsl:output method="xml" indent="yes"/>

   <xsl:param name="validation-phase" select="'terse'"/>
   <xsl:param name="is-validation" select="false()"/>
   <xsl:param name="distribute-vocabulary" select="false()"/>

   <xsl:template match="/">
      <test>
         <xsl:message select="'Testing ' || $doc-id || 'at' || $doc-uri"/>
         <!--<self-r><xsl:copy-of select="$self-resolved"/></self-r>-->
         <!--<sources-r><xsl:copy-of select="$sources-resolved"/></sources-r>-->
         <self-e><xsl:copy-of select="$self-expanded"/></self-e>
         <!--<lxx-resolved><xsl:copy-of select="$sources-resolved[*/tan:body/@xml:lang = 'grc']"/></lxx-resolved>-->
         <!--<self-lxx><xsl:copy-of select="$self-expanded/tan:TAN-T/tan:body[@xml:lang = 'grc']/tan:div"/></self-lxx>-->
         <!--<xsl:copy-of select="tan:merge-expanded-docs($self-expanded[tan:TAN-T])"/>-->
      </test>
   </xsl:template>

</xsl:stylesheet>
