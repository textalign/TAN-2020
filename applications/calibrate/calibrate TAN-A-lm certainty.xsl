<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to the TAN application for calibrating the certainty of TAN-A-lm files. -->
    
    <!-- This is the public face of the application. The application proper can be found by
      following any links in an <xsl:include> or <xsl:import>. You are invited to alter any of 
      the parameters in this file as you like, to customize the application. You may want to 
      make copies of this file, to apply to specific situations.
   -->
    
    <!-- DESCRIPTION -->
    
    <!-- Primary (catalyzing) input: any TAN-A-lm file -->
    <!-- Secondary input: none -->
    <!-- Primary output: the TAN-A-lm file with certainty recalibrated -->
    <!-- Secondary output: none. -->
    
    <!-- This application is useful when editing TAN-A-lm files. Very frequently, when using
        local language resources to generate a fresh TAN-A-lm file for a class-1 file, the results 
        are very dirty, and normally involves the deletion of many entries. While editing, one can 
        run that TAN-A-lm file through this application to refresh the certainty rates. This, in turn
        makes interim TAN-A-lm files that have yet to be finished nevertheless more useful for other
        applications, such as the quotation checking application. A second way this may be useful is
        when editing a language-specific TAN-A-lm file, where you might be recalibrating the 
        certainty values of some lm combinations. You can promote an LM option by increasing by an
        arbitrary value its @cert, or demote it by decreasing it. Then running the results through
        this application will recalibrate the entries to 1. -->

    <!-- Nota bene: -->
    <!-- * Input is not resolved ahead of time, so inclusions are ignored. -->
    <!-- * Calibration is not applied to <tok>, only to <lm>s within any <ana>. The certainty
        of <tok> is difficult to calibrate because of the complexities involved in @ref, @rgx, 
        and @chars. A future version of this application may support that feature. --> 
    
    <!-- THE APPLICATION -->
    
    <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
    <xsl:include href="incl/calibrate%20TAN-A-lm%20certainty%20core.xsl"/>

</xsl:stylesheet>
