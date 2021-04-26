<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to the TAN application for creating a catalog file. -->
    
    <!-- This is the public face of the application. The application proper can be found by
      following any links in any <xsl:include> or <xsl:import>. You are invited to alter any 
      parameter in this file as you like, to customize the application. You may want to 
      make copies of this file, with parameters preset to apply to specific situations.
   -->
    
    <!-- DESCRIPTION -->
    
    <!-- Primary (catalyzing and main) input: any XML file -->
    <!-- Secondary input: none -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: a new catalog file for select files in the input file's directory, and perhaps 
        subdirectories. If the collection is TAN-only, the filename will be catalog.tan.xml, otherwise
        catalog.xml. -->
    
    <!-- Every catalog file is an XML file with a root element <collection> with children elements <doc>.
        Both <collection> and <doc> are in no namespace. <doc> can contain anything, but it is arbitrary. -->
    
    <!-- Nota bene: -->
    <!-- * Files with the name catalog.tan.xml and catalog.xml will be ignored. -->
    <!-- * Only files available as an XML document will be catalogued. -->


    <!-- PARAMETERS -->
    
    <!-- Do you wish to catalog only TAN files? -->
    <xsl:param name="tan-only" as="xs:boolean" select="true()"/>
    
    <!-- Do you want to embed in each <doc> listing a TAN file the entirety of the contents of the resolved 
        <head>, or do you want only minimal metadata (the children of <head> before <vocabulary-key>)? -->
    <xsl:param name="include-fully-resolved-metadata" as="xs:boolean" select="false()"/>
    
    <!-- What files do you want to exclude from results? Expected: a regular expression. It is recommended
        that you include /\. because that pattern will ignore hidden files and directories, such as those used
        in Git or other version control managers. -->
    <xsl:param name="exclude-filenames-that-match-what-pattern" as="xs:string?"
        select="'private-|temp-|/\.'"/>
    
    <!-- Do you wish to index deeply? If true, then the catolog file will look in subdirectories for 
        candidate documents. -->
    <xsl:param name="index-deeply" as="xs:boolean" select="true()"/>
    
    

    <xsl:include href="incl/create%20catalog%20file%20core.xsl"/>
    
    
</xsl:stylesheet>
