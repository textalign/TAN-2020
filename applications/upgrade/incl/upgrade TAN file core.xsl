<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- Core application for upgrading a TAN file. -->
   
   <xsl:import href="../../../functions/TAN-function-library.xsl"/>
   <xsl:output use-character-maps="tan:see-special-chars"/>
   
   <!-- About this stylesheet -->
   
   <xsl:param name="stylesheet-iri"
      select="'tag:textalign.net,2015:stylesheet:upgrade-tan'"/>
   <xsl:param name="stylesheet-url" select="static-base-uri()"/>
   <xsl:param name="tan:change-message" select="'Upgrading ' || $tan:doc-uri || ' to ' || $tan:TAN-version"/>
   <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
   
   
   <!-- The application -->
   
   <xsl:variable name="unsupported-versions" select="('1 dev', '2018')" as="xs:string+"/>
   
   <xsl:variable name="doc-tan-version" select="/tan:*/@TAN-version" as="xs:string?"/>
   
   <xsl:variable name="versions-to-parse" as="xs:string*"
      select="subsequence($tan:previous-TAN-versions, index-of($tan:previous-TAN-versions, $doc-tan-version))"/>
   
   <xsl:variable name="this-doc-pass-1" as="document-node()?">
      <xsl:iterate select="$versions-to-parse">
         <xsl:param name="doc-so-far" as="document-node()" select="$tan:orig-self"/>
         
         <xsl:on-completion>
            <xsl:sequence select="$doc-so-far"/>
         </xsl:on-completion>
         
         <xsl:variable name="this-version" select="." as="xs:string"/>
         
         <xsl:variable name="new-doc" as="document-node()">
            <xsl:choose>
               <xsl:when test="$this-version eq '2020'">
                  <xsl:apply-templates select="$doc-so-far" mode="tan:tan-2020-to-2021"/>
               </xsl:when>
               <xsl:otherwise>
                  
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         <xsl:next-iteration>
            <xsl:with-param name="doc-so-far" as="document-node()" select="$new-doc"/>
         </xsl:next-iteration>
         
      </xsl:iterate>
   </xsl:variable>
   
   <xsl:mode name="tan:tan-2020-to-2021" on-no-match="shallow-copy"/>
   
   <xsl:template match="@TAN-version" mode="tan:tan-2020-to-2021">
      <xsl:attribute name="TAN-version">2021</xsl:attribute>
   </xsl:template>
   
   
   <xsl:variable name="this-doc-pass-2" as="document-node()">
      <xsl:choose>
         <xsl:when test="$tan:set-each-doc-node-on-new-line">
            <xsl:apply-templates select="$this-doc-pass-1" mode="tan:doc-nodes-on-new-lines"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$this-doc-pass-1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   
   <!-- Main output -->
   
   <xsl:template match="/">
      <xsl:choose>
         <xsl:when test="$tan:doc-class eq 0">
            <xsl:message select="'This application may be applied only to TAN files.'"/>
         </xsl:when>
         <xsl:when test="string-length($doc-tan-version) lt 1">
            <xsl:message select="'A TAN version must be specified in the document root element @TAN-version.'"/>
         </xsl:when>
         <xsl:when test="$doc-tan-version eq $tan:TAN-version">
            <xsl:message select="'File at ' || $tan:doc-uri || ' is already the latest TAN version.'"/>
         </xsl:when>
         <xsl:when test="$doc-tan-version = $unsupported-versions">
            <xsl:message select="'File at ' || $tan:doc-uri || ' is TAN version ' || $doc-tan-version || ', whose upgrade is not supported by this application. Try application in alpha release TAN-2020.'"/>
         </xsl:when>
         <xsl:when test="not($doc-tan-version = $tan:previous-TAN-versions)">
            <xsl:message select="'Unregonized TAN version ' || $doc-tan-version"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$this-doc-pass-2"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
</xsl:stylesheet>
