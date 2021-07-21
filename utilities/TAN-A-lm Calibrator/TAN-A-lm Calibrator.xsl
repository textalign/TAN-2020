<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to TAN-A-lm Calibrator, the TAN application that recalibrates TAN-A-lm certainty -->
    <!-- Welcome to Application to calibrate the certainty of TAN-A-lm files, the TAN application -->
    <!-- Version 2021-07-07-->
    
    <!-- This application is useful when editing TAN-A-lm files. Very frequently, when using local language
      resources to generate a fresh TAN-A-lm file for a class-1 file, the results are very dirty.
      Cleaning up the file normally involves deleting many entries, so that alternative options' certainty
      rates no longer add to a whole 1.0. Or perhaps certainty has not even been set, and it needs to be
      added. This application will refresh the certainty rates of a TAN-A-lm, making it more useful for
      applications that rely on certainty rates for scoring, such Tangram. A second way this may be
      useful is for edits to language-specific TAN-A-lm file, where you might be recalibrating the
      certainty values of some lm combinations. Perhaps a wordform that has ten lexicomorphological
      resolutions, each one with a detailed @cert value. You want to promote one of the options as being
      slightly more probable, but you do not want to recalculate all the values so they add to 1.0. You
      can increase or decrease the @cert value of an option, then run the file through this application
      to recalibrate all entries so they add to 1.0 certainty. -->
    
    <!-- This is the public interface for the application. The code that runs the application can
        be found by following the links in the <xsl:include> or <xsl:import> at the bottom of this
        file. You are invited to alter as you like any of the parameters in this file, to customize
        the application to suit your needs. If you are relatively new to XSLT, or you are nervous
        about making changes, make a copy of this file before changing it, or configure a
        transformation scenario in Oxygen. If you are comfortable with XSLT, try creating your own
        stylesheet, then import this one, selectively changing the parameters as needed.-->
    
    
    <!-- DESCRIPTION -->
    
    <!-- Primary input: any TAN-A-lm file -->
    <!-- Secondary input: none -->
    <!-- Primary output: the TAN-A-lm file with certainty recalibrated -->
    <!-- Secondary output: none. -->
    
    
    <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
    <!-- * Look at ways to adjust tok certainty -->

    <!-- Nota bene: 
        * Input is not resolved ahead of time, so inclusions are ignored. 
        * Calibration is not applied to <tok>, only to <lm>s within any <ana>. The certainty
        of <tok> is difficult to calibrate because of the complexities involved in @ref, @rgx, 
        and @chars. A future version of this application may support that feature. --> 
    

    <!-- PARAMETERS -->
    
    <!-- No parameters affect the behavior of this version of this application. -->


    <!-- THE APPLICATION -->
    
    <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
    <xsl:include href="incl/TAN-A-lm%20Calibrator%20core.xsl"/>

</xsl:stylesheet>
