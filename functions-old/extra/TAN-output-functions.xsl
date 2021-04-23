<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" exclude-result-prefixes="#all" version="3.0">
   <!-- This is a special set of functions for generating secondary output. See also 
      applications/get%20inclusions/save-files.xsl, which has items that might mature and
      migrate here. -->

   <!-- templates for marking documents to be saved, and for saving them as well -->
   <xsl:output name="xml" method="xml" use-character-maps="tan"/>
   <xsl:output name="xml-indent" method="xml" indent="yes" use-character-maps="tan"/>
   <xsl:output name="html" method="html"/>
   <xsl:output name="html-noindent" method="html" indent="no"/>
   <xsl:output name="xhtml" method="xhtml"/>
   <xsl:output name="xhtml-noindent" method="xhtml" indent="no"/>
   <xsl:output name="text" method="text"/>
   
   <!-- What default output should be used? -->
   <xsl:param name="default-output-method" as="xs:string" select="'xml'"/>
   
   <!-- SAVING FILES -->
   <!-- Note, due to security concerns, functions cannot be used to save documents -->
   <!-- Saving can happen only through a named or moded template -->
   <!-- The mode save-file is completely consumptive; no output is returned -->
   
   <xsl:template match="node() | @*" mode="save-file"/>
   <xsl:template match="/" mode="save-file">
      <xsl:param name="save-as" as="xs:string?"/>
      <xsl:variable name="this-save-as"
         select="
            if (string-length($save-as) gt 0) then
               $save-as
            else
               */(@save-as | @_target-uri)[1]"
      />
      <xsl:variable name="this-target-format" select="*/@_target-format"/>
      <xsl:if test="exists($this-save-as)">
         <xsl:message select="'Saving file as', $this-save-as/string()"/>
         <xsl:result-document href="{$this-save-as}" format="{($this-target-format, $default-output-method)[1]}">
            <xsl:apply-templates mode="#current"/>
         </xsl:result-document>
      </xsl:if>
   </xsl:template>
   <xsl:template match="/comment() | /processing-instruction()" priority="1" mode="save-file">
      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:if test="$set-each-doc-node-on-new-line">
         <xsl:value-of select="'&#xa;'"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="/*[@save-as | @_target-uri | @_target-format]" priority="1" mode="save-file">
      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:if test="$set-each-doc-node-on-new-line">
         <xsl:value-of select="'&#xa;'"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@* except (@save-as | @xml:base | @_target-uri |@_target-format)"/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template name="save-file">
      <xsl:param name="document-to-save" as="document-node()" required="yes"/>
      <xsl:param name="save-as" as="xs:string?"/>
      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:apply-templates select="$document-to-save" mode="save-file">
         <xsl:with-param name="save-as" select="$save-as"/>
      </xsl:apply-templates>
   </xsl:template>
   
   
   
</xsl:stylesheet>
