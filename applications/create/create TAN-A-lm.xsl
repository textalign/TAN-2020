<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to the TAN application for creating a TAN-A-lm file. -->
    
    <!-- This is the public face of the application. The application proper can be found by
      following any links in any <xsl:include> or <xsl:import>. You are invited to alter any 
      parameter in this file as you like, to customize the application. You may want to 
      make copies of this file, with parameters preset to apply to specific situations.
   -->
    
    <!-- DESCRIPTION -->
    
    <!-- Primary (catalyzing) input: any class 1 TAN file -->
    <!-- Secondary (main) input: a TAN-A-lm file populated with values that best resemble the intended 
        final output; language catalogs; perhaps language search services. -->
    <!-- Primary output: a new TAN-A-lm file freshly populated with lexicomorphological data, sorted with 
        the data most likely in need of editing at the top. -->
    <!-- Secondary output: none -->
    
    <!-- Well-curated lexico-morphological data is highly valuable for a variety of applications such as
        quotation detection, stylometric analysis, and machine translation. This application will process
        any TAN-T or TAN-TEI file through existing TAN-A-lm language libraries, and online search services,
        looking for the best lexico-morphological profiles for the file's tokens. 
    -->
    
    <!-- OPTIMIZATION STRATEGIES ADOPTED -->
    <!-- Minimize the number of times files in the language catalog must be consulted and resolved -->
    <!-- In the interests of efficient processing, if a hit on @val be taken as the best answer, and preclude 
        searches on @rgx or via online search services -->
    <!-- We assume that a search for lexico-morphological data will entail a lot of different TAN-A-lm files 
        with a number of conventions. Codes found in language catalogs must be converted to TAN-standardized 
        feature names, and then reconverted into the codeset of choice, dictated by the <morphology> in the 
        template TAN-A-lm file. -->

    <!-- Nota bene: -->
    <!-- * There must be access to a language catalog, i.e., a collection of TAN-A-lm files that are 
        language specific. -->
    <!-- * The TAN-A-lm is relied upon as dictating the settings for the file, e.g., tokenization pattern,
        TAN-mor morphology, etc. -->


    <xsl:include href="incl/create%20TAN-A-lm%20core.xsl"/>
    
    
    <!-- PARAMETERS -->
    
    <!-- Any parameter below whose name begins "tan:" is a global parameter, and corresponds to a
      parameter in the parameters subdirectory. It is repeated here, because one commonly wishes to 
      make special exceptions from the default, for this particular application. -->
    
    <!-- THE TAN-A-LM TEMPLATE -->
    
    <!-- Where is the TAN-A-lm file that should be used as a template for the output? The target uri
        must be resolved. By default, a search is made in the input for the first annotation location. -->
    <xsl:param name="template-tan-a-lm-uri-resolved" as="xs:string"
        select="base-uri($tan:annotations-1st-da[tan:TAN-A-lm][1])"/>
    
    <!-- LEXICOMORPHOLOGICAL DATA SOURCES: LANGUAGE CATALOGS AND SEARCH SERVICES -->
    
    <!-- Do you want to search for lexicomorphological data through a supported internet-based service?
        At present, only Morpheus's service, for Greek and Latin, is supported. -->
    <xsl:param name="use-search-services" as="xs:boolean" select="true()"/>
    
    <!-- Do you want to use a search service only if local lexico-morphological data fails to be 
        found? If false, then online searches will be made on every word form for every available search
        service. -->
    <xsl:param name="use-search-services-only-as-backup" as="xs:boolean" select="false()"/>
    
    <!-- Do you want to assume that any morphological codes retrieved from the local language catalog are
        to be retained as-is, without checking their underlying meaning? If true, then performance should
        be relatively speedy. If there are problems, they can be resolved when editing the output, in light
        of validation reports. If false, then the process may be very slow (perhaps twenty times longer), 
        because every morphological code will need to be converted to a series of IRI values, which will 
        then need to be reconverted into the template TAN-A-lm file's declared system. -->
    <xsl:param name="retain-morphological-codes-as-is" as="xs:boolean" select="true()"/>
    <!-- As of April 2021, false() is not supported for the parameter above. -->
    
    <!-- OUTPUT -->
    
    <!-- Do you wish an output <tok> pointing to a single token to be accompanied by a comment giving
        the context of the word? Any integer 1 or higher turns this feature on, and supplies that many
        words on either side of the target token. -->
    <xsl:param name="insert-tok-context" as="xs:integer?" select="3"/>
    
</xsl:stylesheet>