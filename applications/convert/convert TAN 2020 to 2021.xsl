<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to the TAN application for converting a TAN file from the 2020 version to 2021. -->
    
    <!-- This is the public face of the application. The application proper can be found by
      following any links in any <xsl:include> or <xsl:import>. You are invited to alter any 
      parameter in this file as you like, to customize the application. You may want to 
      make copies of this file, with parameters preset to apply to specific situations.
   -->
    
    <!-- DESCRIPTION -->
    
    <!-- Primary (catalyzing) input: any TAN file version 2020 -->
    <!-- Secondary (main) input: none. -->
    <!-- Primary output: the TAN file converted to 2021. -->
    <!-- Secondary output: none -->
    

    <!-- Nota bene: -->
    <!-- * To convert TAN files from a version earlier than 2020, use applications released with  
        prior alpha versions. -->


    <xsl:include href="incl/convert%20TAN%202020%20to%202021%20core.xsl"/>
    
    
</xsl:stylesheet>
