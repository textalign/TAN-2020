<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0">
   
   <xsl:function name="tan:generate-save-uris" as="xs:string*">
      <!-- 3-param version of fuller one, below -->
      <xsl:param name="items-to-be-saved" as="item()*"/>
      <xsl:param name="prefix" as="xs:string?"/>
      <xsl:param name="suffix" as="xs:string?"/>
      <xsl:param name="target-base-uri" as="xs:string?"/>
      <xsl:copy-of select="tan:generate-save-uris($items-to-be-saved, $prefix, $suffix, $target-base-uri, 'xml')"/>
   </xsl:function>
   <xsl:function name="tan:generate-save-uris" as="xs:string*">
      <!-- Input: items that are intended for saving; a base uri, a prefix -->
      <!-- Output: one unique resolved uri per item -->
      <xsl:param name="items-to-be-saved" as="item()*"/>
      <xsl:param name="prefix" as="xs:string?"/>
      <xsl:param name="suffix" as="xs:string?"/>
      <xsl:param name="target-base-uri" as="xs:string?"/>
      <xsl:param name="extension" as="xs:string?"/>
      <xsl:variable name="count-input-items" select="count($items-to-be-saved)"/>
      <xsl:for-each select="$items-to-be-saved">
         <xsl:variable name="this-id" select="root(.)/*/@id"/>
         <xsl:variable name="this-filename" select="tan:cfn(.)"/>
         <xsl:variable name="this-item-uri-fragment" as="xs:string?">
            <xsl:choose>
               <xsl:when test="$count-input-items lt 1"/>
               <xsl:when test="string-length($this-filename) gt 0">
                  <xsl:value-of select="$this-filename"/>
               </xsl:when>
               <xsl:when test="string-length($this-id) gt 0">
                  <xsl:value-of select="encode-for-uri($this-id)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="xs:string(position())"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="this-filename"
            select="concat(string-join(($prefix, $this-item-uri-fragment, $suffix), '-'), '.', ($extension, 'xml')[1])"
         />
         <xsl:value-of select="resolve-uri($this-filename, $target-base-uri)"/>
      </xsl:for-each>
   </xsl:function>
   
   <!-- MARKING FILES TO BE SAVED -->
   <xsl:function name="tan:mark-save-as" as="item()*">
      <!-- Input: any document; a string representing a local uri -->
      <!-- Output: the same document, with @save-as stamped in the root element -->
      <xsl:param name="items-to-mark-for-saving" as="item()*"/>
      <xsl:param name="save-as-uri" as="xs:string*"/>
      <xsl:variable name="item-count" select="count($items-to-mark-for-saving)"/>
      <xsl:variable name="uri-count" select="count($save-as-uri)"/>
      <xsl:choose>
         <xsl:when test="$item-count gt 0 and $uri-count lt $item-count">
            <xsl:message
               select="'There are', $item-count, 'items to be saved but only', $uri-count, 'uris'"/>
         </xsl:when>
      </xsl:choose>
      <xsl:for-each select="$items-to-mark-for-saving">
         <xsl:variable name="pos" select="position()"/>
         <xsl:variable name="this-node-type" select="tan:node-type(.)"/>
         <xsl:variable name="this-uri" select="$save-as-uri[$pos]"/>
         <xsl:choose>
            <xsl:when test="not($this-node-type = 'document-node')">
               <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
               <xsl:message select="$this-node-type, 'at', $this-base-uri, 'cannot be marked for saving at', $save-as-uri"/>
            </xsl:when>
            <xsl:when test="not(exists($this-uri))">
               <xsl:message select="'No uri provided to mark where the document should be saved.'"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="." mode="stamp-save-as">
                  <xsl:with-param name="save-as-uri" select="$this-uri" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:template match="/*" mode="stamp-save-as">
      <xsl:param name="save-as-uri" as="xs:string?" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="string-length($save-as-uri) gt 0">
            <xsl:attribute name="save-as" select="$save-as-uri"/>
         </xsl:if>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   
</xsl:stylesheet>
