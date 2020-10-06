<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0">
   <xsl:variable name="extra-parameters-base-uri" select="static-base-uri()"/>
   <!-- If a file to be opened cannot be read as Unicode, what is the preferred default encoding that should be tried? -->
   <xsl:param name="fallback-encoding" as="xs:string?" select="'cp1252'"/>
   <!-- Language catalogs -->
   <xsl:param name="lang-catalog-map" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'grc'">
            <xsl:text>../../library-lm/grc/lm-perseus/catalog.tan.xml</xsl:text>
            <xsl:text>../../library-lm/grc/lm-bible/catalog.tan.xml</xsl:text>
         </xsl:map-entry>
         <xsl:map-entry key="'lat'">
            <xsl:text>../../library-lm/lat/lm-perseus/catalog.tan.xml</xsl:text>
         </xsl:map-entry>
      </xsl:map>
   </xsl:param>
   
   <!-- regular expressions to detect the end of sentences, clauses, and words -->
   <!-- What regular expression defines the end of a sentence? -->
   <xsl:param name="sentence-end-regex" select="'[\.\?!]+\p{P}*[\s.]*'"/>
   <!-- What regular expression defines the end of a clause? The default regular expression seeks to avoid words terminated by a simple apostrophe, and anticipates ellipses. -->
   <xsl:param name="clause-end-regex" as="xs:string">[\w\s][\p{P}-[&apos;’«\[\(-]]\p{P}*[\s.]*</xsl:param>
   <!-- What regular expression defines the end of a word? -->
   <xsl:param name="word-end-regex" select="'\s+'"/>
   
   
   <!-- Batch replacements, applicable across many languages. For language-specific
   batch replacements, see extra/TAN-language-functions.xsl. Batch replacements are
   sequences of elements with attributes corresponding to fn:replace(): @pattern,
   @replacement, @flags. There is also a @message option, to report back on 
   changes taking place. -->
   
   <!-- What batch replacements should be applied to punctuation? -->
   <xsl:param name="batch-replace-punctuation" as="element()*">
      <replace pattern="\p{{P}}+" replacement="" message="Removing punctuation"/>
   </xsl:param>
   <!-- What batch replacements should be applied to combining marks? -->
   <xsl:param name="batch-replace-combining-marks" as="element()*">
      <replace pattern="\p{{Mc}}+" replacement="" message="Removing combining marks"/>
   </xsl:param>
   
</xsl:stylesheet>
