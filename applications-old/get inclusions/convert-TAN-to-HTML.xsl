<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">

    <!-- Basic conversion utility for TAN to html -->
    <!-- Must be imported or included by a master stylesheet that also includes the TAN function library, perhaps by also importing convert.xsl -->

    <xsl:param name="attribute-values-to-add-to-class-attribute" as="xs:string*" select="('type')"/>
    <xsl:param name="attributes-to-convert-to-elements" as="xs:string*"
        select="('href', 'accessed-when', 'type', 'resp', 'wit', 'rend', 'cRef')"/>
    <xsl:param name="attributes-to-retain" as="xs:string*" select="('xml:lang', 'src-qualifier')"/>
    <xsl:param name="children-element-values-to-add-to-class-attribute" as="xs:string*"
        select="('type')"/>
    <xsl:param name="elements-to-be-labeled" as="xs:string*" select="()"/>
    <xsl:param name="elements-whose-children-should-be-grouped-and-labeled" as="xs:string*"
        select="('teiHeader', 'head', 'vocabulary-key', 'adjustments')"/>
    <xsl:param name="elements-who-should-not-be-grouped-and-labeled" as="xs:string*"
        select="('src')"/>
    <!-- Normally, if something is really to be hidden, it should be done via CSS. If you wish
    some elements to be hidden depending upon whether the first sibling is a label or .showAll
    that too is best handled by CSS, not here. -->
    <xsl:param name="elements-to-be-given-class-hidden" as="xs:string*" select="()"/>

    <xsl:param name="td-widths-proportionate-to-string-length" as="xs:boolean" select="false()"/>
    <xsl:param name="td-widths-proportionate-to-td-count" as="xs:boolean" select="false()"/>

    <xsl:function name="tan:tan-to-html" as="item()*">
        <!-- Input: TAN XML -->
        <!-- Output: HTML -->
        <xsl:param name="tan-input" as="item()*"/>
        <xsl:variable name="pass-1" as="item()*">
            <xsl:apply-templates select="$tan-input" mode="tan-to-html-pass-1"/>
        </xsl:variable>
        <xsl:variable name="pass-2" as="item()*">
            <!-- make your own rules and changes! -->
            <xsl:apply-templates select="$pass-1" mode="tan-to-html-pass-2"/>
        </xsl:variable>
        <xsl:variable name="pass-3" as="item()*">
            <xsl:apply-templates select="$pass-2" mode="tan-to-html-pass-3"/>
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:choose>
            <xsl:when test="$diagnostics-on">
                <xsl:message>diagnostics turned on for tan:tan-to-html()</xsl:message>
                <xsl:document>
                    <diagnostics-for-tan-to-html>
                        <pass-1><xsl:copy-of select="$pass-1"/></pass-1>
                        <pass-2><xsl:copy-of select="$pass-2"/></pass-2>
                        <pass-3><xsl:copy-of select="$pass-3"/></pass-3>
                    </diagnostics-for-tan-to-html>
                </xsl:document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$pass-3"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="html:*" priority="1" mode="tan-to-html-pass-1 tan-to-html-pass-2 tan-to-html-pass-3">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- pass 1: get rid of unnecessary things, and start building @class; the conversion to html elements does not happen yet -->

    <!-- generally speaking, TAN comments, p-i's, and attributes may be ignored (expansion converts overloaded attributes into elements) -->
    <xsl:template match="comment() | processing-instruction()" mode="tan-to-html-pass-1"/>
    <xsl:template match="@*" mode="tan-to-html-pass-1">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:variable name="this-local-name" select="local-name(.)"/>
        <xsl:if test="$this-name = $attributes-to-retain">
            <!-- If an @xml:lang or similar attribute is passed, get rid of the prefix -->
            <xsl:attribute name="{$this-local-name}" select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:cf | tan:see-q" mode="tan-to-html-pass-1"/>

    <xsl:template match="@q | @id" mode="tan-to-html-pass-1">
        <xsl:attribute name="id" select="."/>
    </xsl:template>

    <xsl:template match="*" mode="tan-to-html-pass-1">
        <!-- Prepare html @class -->
        <xsl:variable name="this-namespace" select="namespace-uri(.)"/>
        <xsl:variable name="parent-namespace" select="namespace-uri(..)"/>
        <xsl:variable name="class-vals-from-attributes"
            select="@*[name(.) = $attribute-values-to-add-to-class-attribute]"/>
        <xsl:variable name="class-vals-from-children"
            select="*[name(.) = $children-element-values-to-add-to-class-attribute]/text()"/>
        <xsl:variable name="other-class-values-to-add" as="xs:string*">
            <xsl:value-of select="name(.)"/>
            <xsl:if test="name(.) = $elements-to-be-given-class-hidden">hidden</xsl:if>
            <xsl:for-each select="tan:cf, tan:see-q">
                <xsl:value-of select="concat('idref--', .)"/>
            </xsl:for-each>
            <xsl:if test="not($this-namespace = $parent-namespace)">
                <xsl:value-of select="tan:namespace($this-namespace)"/>
            </xsl:if>
            <xsl:for-each select="distinct-values(tan:src)">
                <xsl:value-of select="concat('src--', .)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="all-class-attribute-values"
            select="tokenize(@class, ' '), $class-vals-from-attributes, $class-vals-from-children, $other-class-values-to-add"
        />
        <!-- get rid of illegal characters for the @class attribute, make sure there's no repetition -->
        <xsl:variable name="all-class-attribute-values-normalized"
            select="
                distinct-values(for $i in $all-class-attribute-values
                return
                    replace($i, '#', ''))"
        />
        <xsl:copy>
            <!-- attributes -->
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="exists($all-class-attribute-values)">
                <xsl:attribute name="class" select="string-join($all-class-attribute-values-normalized, ' ')"/>
            </xsl:if>
            <!-- child elements -->
            <xsl:apply-templates select="@*[name(.) = $attributes-to-convert-to-elements]"
                mode="attr-to-element"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*" mode="attr-to-element">
        <xsl:variable name="parent-namespace" select="namespace-uri(..)"/>
        <xsl:element name="{name(.)}" namespace="{$parent-namespace}">
            <xsl:attribute name="class" select="name(.)"/>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="@href" mode="attr-to-element">
        <xsl:element name="a" namespace="tag:textalign.net,2015:ns">
            <xsl:attribute name="href" select="."/>
            <!-- oftentimes @href is within <location>, so we use the name of the host element as anchor text -->
            <xsl:value-of select="name(..)"/>
        </xsl:element>
    </xsl:template>

    <!-- pass 2: reserved for individual situations (e.g., processes that use TAN-T_merge might need to untangle sources a bit) -->


    <!-- pass 3: convert everything to html <div> -->

    <xsl:template match="*" mode="tan-to-html-pass-3">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:variable name="children-should-be-grouped-and-labeled-by-source"
            select="$this-name = $elements-whose-children-should-be-grouped-and-labeled"/>
        <div>
            <xsl:copy-of select="@*"/>
            <xsl:if test="name(.) = $elements-to-be-labeled">
                <div class="label">
                    <xsl:value-of select="name(.)"/>
                </div>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$children-should-be-grouped-and-labeled-by-source">
                    <xsl:variable name="children-not-to-group"
                        select="(*[name(.) = $elements-who-should-not-be-grouped-and-labeled], html:*)"
                    />
                    <xsl:variable name="children-to-group" select="* except $children-not-to-group"/>
                    <xsl:apply-templates select="$children-not-to-group" mode="#current"/>
                    <xsl:for-each-group select="$children-to-group" group-adjacent="name(.)">
                        <xsl:variable name="this-count" select="count(current-group())"/>
                        <xsl:variable name="this-suffix"
                            select="
                                if ($this-count gt 1) then
                                    concat('s (', string($this-count), ')')
                                else
                                    ()"/>
                        <div class="group">
                            <div class="label">
                                <xsl:value-of select="current-grouping-key()"/>
                                <xsl:value-of select="$this-suffix"/>
                            </div>
                            <xsl:apply-templates select="current-group()" mode="#current"/>
                        </div>
                    </xsl:for-each-group> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current"/> 
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="tan:a" mode="tan-to-html-pass-3">
        <a>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </a>
    </xsl:template>


</xsl:stylesheet>
