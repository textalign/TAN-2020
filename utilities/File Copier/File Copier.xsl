<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to File Copier, the TAN application that copies a file to a location, updating
      internal relative URLs -->
   <!-- Version 2021-07-07-->

   <!-- This is the public interface for the application. The code that runs the application can
      be found by following the links in the <xsl:include> or <xsl:import> at the bottom of this
      file. You are invited to alter as you like any of the parameters in this file, to customize
      the application to suit your needs. If you are relatively new to XSLT, or you are nervous
      about making changes, make a copy of this file before changing it, or configure a
      transformation scenario in Oxygen. If you are comfortable with XSLT, try creating your own
      stylesheet, then import this one, selectively changing the parameters as needed.-->
   

   <!-- DESCRIPTION -->

   <!-- Primary (catalyzing) input: any file -->
   <!-- Secondary input: none (but see parameters) -->
   <!-- Primary output: none -->
   <!-- Secondary output: the file copied to the target location, revising any relative @hrefs in light of
      the target location -->

   <!-- Nota bene:
      * Links are based on common constructs: @href everywhere, but @src only in HTML files. Processing
      instructions will be parsed for @href values.
   -->

   <!-- PARAMETERS -->

   <!-- To what path should the file be copied? If a relative path, it will be resolved against the base
      path of the catalyzing input. -->
   <xsl:param name="target-uri" as="xs:string" required="yes"/>

   <!-- Do you wish to convert any relative links to absolute links before saving? -->
   <xsl:param name="convert-relative-links-to-absolute" as="xs:boolean" select="true()"/>

   <!-- Do you wish to update links based on the target location? If yes, then any absolute URIs 
        that share part of the path of the target location will be converted to relative paths. Note,
        this parameter will not have any effect on relative paths that have not been converted to
        absolute paths first (see above).
    -->
   <xsl:param name="relativize-links-to-target" as="xs:boolean" select="true()"/>


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/File%20Copier.xsl"/>

</xsl:stylesheet>
