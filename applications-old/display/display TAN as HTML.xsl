<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    tan:test="hello"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Primary (catalyzing) input: any TAN file -->
    <!-- Secondary input: none -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: an HTML file -->
    <!-- Resultant output will need attention, because of how unpredictable CSS and JavaScript dependencies might be. -->
    
    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="false()"/>
    
    <!--<xsl:import href="../get%20inclusions/convert.xsl"/>-->
    <xsl:include href="../../functions/TAN-A-functions.xsl"/>
    <xsl:include href="../../functions/TAN-extra-functions.xsl"/>
    <xsl:include href="../get%20inclusions/convert-TAN-to-HTML.xsl"/>
    <xsl:import href="../../parameters/application-parameters.xsl"/>
    
    <xsl:output method="html" use-when="not($output-diagnostics-on)"/>
    <xsl:output method="xml" indent="yes" use-when="$output-diagnostics-on"/>
    
    
    <!-- THIS STYLESHEET -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:display-tan-as-html'"/>
    <xsl:param name="stylesheet-name" select="'TAN to HTML converter'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="change-message" select="'Converted tan file to html. The quality of results will depend significantly upon any linked CSS or JavaScript files.'"/>
    <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-07-28">Need to wholly overhaul the default CSS and JavaScript files in output/css and output/js</comment>
            <comment who="kalvesmaki" when="2020-07-28">Need to build parameters to allow users to drop elements from the HTML DOM.</comment>
        </to-do>
    </xsl:param>
    
    <!-- What form of the TAN file do you wish to view: 'raw' (default), 'resolved', or 'expanded'? -->
    <xsl:param name="TAN-file-state" as="xs:string?" select="'raw'"/>
    
    <xsl:param name="validation-phase" select="'terse'"/>
    <xsl:param name="html-template-uri-resolved" select="$default-html-template-uri-resolved"/>
    
    <!-- START OF PROCESS -->
    
    <xsl:variable name="input-item" as="document-node()?">
        <xsl:choose>
            <xsl:when test="$TAN-file-state = 'expanded'">
                <xsl:sequence select="$self-expanded[1]"/>
            </xsl:when>
            <xsl:when test="$TAN-file-state eq 'resolved'">
                <xsl:sequence select="$self-resolved"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$orig-self"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="input-item-revised" select="tan:revise-hrefs($input-item, $doc-uri, $html-template-uri-resolved)"/>
    <xsl:variable name="input-as-html" select="tan:tan-to-html($input-item-revised)" as="item()*"/>
    
    <xsl:variable name="html-template-doc" select="doc($html-template-uri-resolved)"/>
    <xsl:variable name="template-infused" as="document-node()?">
        <xsl:apply-templates select="$html-template-doc" mode="infuse-html-template"/>
    </xsl:variable>
    <xsl:template match="html:body/html:div[1]" mode="infuse-html-template">
        <xsl:apply-templates select="$input-as-html" mode="#current"/>
    </xsl:template>
    
    <xsl:variable name="output-with-hrefs-fixed" select="tan:revise-hrefs($template-infused, $html-template-uri-resolved, $target-output-directory-resolved)"/>
    
    
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Diagnostics on for ' || static-base-uri()"/>
        <diagnostics>
            <input-as-html><xsl:copy-of select="$input-as-html"/></input-as-html>
            <html-template><xsl:copy-of select="$html-template-doc"/></html-template>
            <template-infused><xsl:copy-of select="$template-infused"/></template-infused>
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:copy-of select="$template-infused"/>
    </xsl:template>

</xsl:stylesheet>
