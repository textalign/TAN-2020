<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
   exclude-result-prefixes="#all" version="3.0">
   <!-- Global parameters pertaining to TAN applications making use of tan:diff() and tan:collate(). 
      This stylesheet is meant to be imported (not included) by other stylesheets, so that the
      parameter values can be changed. -->
   
   <!-- DIFF/COLLATE INPUT ADJUSTMENT -->

   <!-- Should punctuation be ignored? -->
   <xsl:param name="ignore-punctuation-differences" as="xs:boolean" select="false()"/>
   
   <!-- Should combining marks be ignored? -->
   <xsl:param name="ignore-combining-marks" as="xs:boolean?" select="false()"/>
   
   <!-- Should differences in case be ignored? -->
   <xsl:param name="ignore-case-differences" as="xs:boolean?" select="false()"/>
   
   <!-- Summary of alterations, if any, that should be made to strings BEFORE tan:diff() 
      or tan:collate() are applied. -->
   <xsl:variable name="diff-and-collate-input-batch-replacements" as="element()*">
      <xsl:if test="$ignore-punctuation-differences">
         <xsl:sequence select="$batch-replace-punctuation"/>
      </xsl:if>
      <xsl:if test="$ignore-combining-marks">
         <xsl:sequence select="$batch-replace-combining-marks"/>
      </xsl:if>
   </xsl:variable>
   
   <!-- DIFF/COLLATE PROCESS PARAMETERS -->
   
   <!-- Should diffs be rendered word-for-word (true) or character-for-character? The former renders imprecise but more legible results; the latter, precise but sometimes illegible results. -->
   <xsl:param name="snap-to-word" as="xs:boolean" select="true()"/>
   
   
   <!-- DIFF/COLLATE STATISTICS -->
   
   <!-- Should Venn diagrams be inserted for collations of 3 or more versions? If true, processing will take longer, and the HTML file will be larger. -->
   <xsl:param name="include-venns" as="xs:boolean" select="false()"/>
   

</xsl:stylesheet>
