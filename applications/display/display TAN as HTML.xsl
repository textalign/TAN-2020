<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to the TAN application for displaying TAN/TEI files as HTML. -->

   <!-- This is the public face of the application. The application proper can be found by
      following any links in any <xsl:include> or <xsl:import>. You are invited to alter any 
      parameter in this file as you like, to customize the application. You may want to 
      make copies of this file, with parameters preset to apply to specific situations.
   -->

   <!-- DESCRIPTION -->

   <!-- Primary (catalyzing) input: a TAN file -->
   <!-- Secondary input: none -->
   <!-- Primary output: if no destination filename is specified, an HTML file -->
   <!-- Secondary output: if a destination filename is specified, an HTML file at the target location -->

   <!-- This application quickly renders a TAN or TEI file as HTML. It has been optimized for JavaScript
      and CSS within the output subdirectory of the TAN structure. -->
   
   <!-- Nota bene:
      * This application can be used to generate primary or secondary output, depending upon how
      parameters are configured (see below).
   -->
   
   

   <!-- PARAMETERS -->
   
   <!-- INPUT ADJUSTMENT -->
   
   <!-- In what state would you like the TAN/TEI file rendered? Options: 'raw' (default), 'resolved', 
      or 'expanded' -->
   <xsl:param name="TAN-file-state" as="xs:string?" select="'expanded'"/>
   
   <!-- If rendering an expanded TAN/TEI file, what level of expansion do you want? Options: 'terse',
      'normal', 'verbose'. -->
   <xsl:param name="tan:validation-phase" select="'terse'"/>
   
   <!-- Do you want to treat the file as if being validated or not? This does not affect either a raw
      or a resolved file, but it will affect the expanded file. In validation mode, only the errors 
      are returned. -->
   <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="false()"/>
   
   
   <!-- OUTPUT -->
   
   <!-- Where is the HTML file that should be used as a template for the TAN/TEI file? -->
   <xsl:param name="html-template-uri-resolved" select="$tan:default-html-template-uri-resolved"/>
   
   
   <!-- Should the file be sent through a preparatory stage before being converted to HTML? If true,
      then tan:prepare-to-convert-to-html() will be invoked, which relies extensively upon the
        global parameters specified at ../../parameters/params-application-html-output.xsl -->
   <xsl:param name="use-function-prepare-to-convert-to-html" as="xs:boolean" select="true()"/>
   
   <!-- Should any hrefs in the text of the source file be converted to hyperlinks in the output? -->
   <xsl:param name="parse-text-for-urls" as="xs:boolean" select="true()"/>
   
   <!-- Where specifically do you want the output inserted? Expected is a string naming the value of 
      @id of some HTML element in the template. If this value is missing or is a zero-length string,
      then the content will be inserted as the first child of the <body> -->
   <xsl:param name="target-id-for-html-content" as="xs:string?"/>
   
   
   <!-- For what directory is the output intended? This is important to reconcile any relative
      links. -->
   <xsl:param name="output-directory-uri" as="xs:string"
      select="$tan:default-output-directory-resolved"/>
   
   
   <!-- What should be the local name of the output file? If this value is null, empty, or only
      space, then the HTML file will be returned as primary output, and it is up to the user to 
      direct it to the proper location. Otherwise it is appended to the value of 
      $output-directory-uri (see above) and returned as secondary output in that location. -->
   <xsl:param name="output-target-filename" as="xs:string?"/>
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/display%20TAN%20as%20HTML%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
   
</xsl:stylesheet>
