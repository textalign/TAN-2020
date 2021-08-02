<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to Updater, the TAN application that converts TAN files from older versions 
        to the current version. -->
    <!-- Version 2021-07-07-->
    
    <!-- This is the public interface for the application. The code that runs the application can be found by
      following the links in the <xsl:include> or <xsl:import> at the bottom of this file. You are invited
      to alter as you like any of the parameters in this file, to customize the application to suit your
      needs. If you are relatively new to XSLT, or you are nervous about making changes, make a copy of
      this file before changing it, or configure a transformation scenario in Oxygen. If you are
      comfortable with XSLT, try creating your own stylesheet, then import this one, selectively changing
      the parameters as needed. For more background on how to configure and use this file, see the TAN
      Guidelines, Using TAN Applications and Utilities. -->
    
    
    <!-- DESCRIPTION -->
    
    <!-- Primary input: any TAN file version 2020 -->
    <!-- Secondary input: none -->
    <!-- Primary output: the TAN file converted to the latest version -->
    <!-- Secondary output: none -->
    

    <!-- Nota bene: -->
    <!-- * To convert TAN files from a version earlier than 2020, use applications released with  
        prior alpha versions. -->
    
    
    <!-- PARAMETERS -->
    
    <!-- No parameters affect the behavior of this version of this application. -->
    

    <!-- The main engine for the application is in this file, and in other files it links to. Feel
        free to explore, but make alterations only if you know what you are doing. If you make
        changes, make a copy of the original file first.-->
    <xsl:include href="incl/Updater%20core.xsl"/>
    
    
</xsl:stylesheet>
