<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- Welcome to the TAN application for synchronizing the text in the body of a class 1 file 
      with one of its <redivision>s. -->
   
   <!-- This is the public face of the application. The application proper can be found by
      following any links in an <xsl:include> or <xsl:import>. You are invited to alter any of 
      the parameters in this file as you like, to customize the application. You may want to 
      make copies of this file, to apply to specific situations.
   -->
   
   <!-- DESCRIPTION -->
   
   <!-- Initial (main) input: a class 1 file -->
   <!-- Secondary input: none (but see parameters) -->
   <!-- Main output: the main input, with the text of its body revised to match the text in the chosen redivision -->
   <!-- Secondary output: none -->
   
   <!-- Nota bene:
      * The comparison can be made only on the basis of space-normalized comparisons, which means that
      the output will have leaf divs without any internal indentation. 
      * If there are any special end-of-div characters to insert, they will be rendered as hexadecimal 
      codepoint entities.
      * Comments and processing instructions inside the body will be retained. If you choose to mark
      alterations, make sure there aren't already some in your file, otherwise it will all get mixed up.
   -->
   
   <!-- PARAMETERS -->
   
   <!-- Feel free to change the parameters as you see fit. Make sure that any new values are acceptable
   types for the specified data type. -->
   
   <!-- Provide a number that specifies which <redivision> should be used as the basis for syncing the text. 
      Default is 1. -->
   <xsl:param name="redivision-number" as="xs:integer" select="1"/>
   
   <!-- Should insertions and deletions be documented in comments? -->
   <xsl:param name="mark-alterations" as="xs:boolean" select="true()"/>
   
   
   <!-- THE APPLICATION -->
   
   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/synchronize%20class%201%20body%20text%20with%20redivision%20core.xsl"/>
   
   
</xsl:stylesheet>