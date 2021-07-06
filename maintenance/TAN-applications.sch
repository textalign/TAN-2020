<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <sch:title>Schematron tests for maintaining the TAN application library</sch:title>
   <sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
   <sch:ns uri="tag:textalign.net,2015:ns" prefix="tan"/>
   
   <xsl:include href="TAN-application-maintenance.xsl"/>
   
   <sch:let name="inclusion-to-main-application" value="/*/xsl:include[1]"/>
   <sch:let name="main-application"
      value="doc(resolve-uri($inclusion-to-main-application/@href, base-uri()))"/>
   
   <sch:let name="app-iri" value="$main-application/*/xsl:param[@name eq 'tan:stylesheet-iri']"/>
   <sch:let name="app-name" value="$main-application/*/xsl:param[@name eq 'tan:stylesheet-name']"/>
   <sch:let name="app-change-message" value="$main-application/*/xsl:param[@name eq 'tan:change-message']"/>
   
   <sch:let name="welcome-message-starter" value="'Welcome to the TAN application'"></sch:let>
   <sch:let name="welcome-message" value="/*/comment()[contains(., $welcome-message-starter)]"/>
   
   <sch:let name="app-preamble"
      value="/*/comment()[normalize-space(.) eq $tan:standard-app-preamble-norm]"/>
   
   
   <sch:pattern>
      <sch:rule context="/*">
         <sch:assert test="exists($main-application)">There must be a main application
            available, through a single xsl:include.</sch:assert>
         <sch:assert test="exists($app-iri)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-iri, declaring the application's
            IRI.</sch:assert>
         <sch:assert test="exists($app-name)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-name, declaring the name of the
            application.</sch:assert>
         <sch:assert test="exists($app-change-message)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:change-message, declaring the change being 
            performed by the application.</sch:assert>
         
         <sch:assert test="exists($welcome-message)">Every TAN application must include a comment welcoming the user to
         the application, identifiable by its starter: 
            <sch:value-of select="$welcome-message-starter"/></sch:assert>
         <sch:assert test="exists($app-preamble)" sqf:fix="std-app-preamble">Every TAN application
            must include the standard preamble.</sch:assert>
         
         <sqf:fix id="std-app-preamble">
            <sqf:description>
               <sqf:title>Add standard preamble to TAN file</sqf:title>
            </sqf:description>
            <sqf:add match="." position="first-child">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:standard-app-preamble-comment"/>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
   </sch:pattern>
   
   
</sch:schema>