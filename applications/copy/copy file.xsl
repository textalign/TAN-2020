<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to the TAN application for synchronizing the text in the body of a class 1 file 
      with one of its <redivision>s. -->

   <!-- This is the public face of the application. The application proper can be found by
      following any links in an <xsl:include> or <xsl:import>. You are invited to alter any of 
      the parameters in this file as you like, to customize the application. You may want to 
      make copies of this file, to apply to specific situations.
   -->

   <!-- DESCRIPTION -->

   <!-- Primary (catalyzing) input: any file -->
   <!-- Secondary input: none (but see parameters) -->
   <!-- Primary output: none -->
   <!-- Secondary output: the file copied to the target location, revising any relative @hrefs in light of the target location -->

   <!-- Nota bene:
      * Links are based on common constructs: @href everywhere, but @src only in HTML files. Processing
      instructions will be parsed for @href values.
   -->

   <!-- PARAMETERS -->

   <!-- To what path should the file be copied? If a relative path, it will be resolved against the base path of the catalyzing input. -->
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
   <xsl:include href="incl/copy%20file%20core.xsl"/>

</xsl:stylesheet>
