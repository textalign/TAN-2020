<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- Core extended parameters for the TAN function library. These parameters may be overwritten, but 
      TAN-static-parameters.xsl. For parameters that most users will likely wish to change, see the
      parameters subdirectory in the TAN project.
   -->

   <!-- APPLICATION STYLESHEET PARAMETERS -->
   
   <!-- Any TAN application must have identifiers, so that credit/blame can be allocated in the output.
   The following are standard parameters. -->
   
   <!-- If the output is a TAN file, the stylesheet should be credited/blamed. That is done primarily through an IRI assigned to the stylesheet -->
   <xsl:param name="tan:stylesheet-iri" as="xs:string" required="no"/>
   
   <!-- What is the name of the stylesheet? This value, along with $stylesheet-iri, will be used to populate the IRI + name pattern when the stylesheet is credited -->
   <xsl:param name="tan:stylesheet-name" as="xs:string" required="no"/>
   
   <!-- Where is the master stylesheet for the application? Normally this means binding this parameter to select="static-base-uri()" -->
   <xsl:param name="tan:stylesheet-url" as="xs:string" required="no"/>
   
   <!-- What does the application do? Phrase it as a change message that might be inserted into the output or returned as a message. How the message is handled is application-dependent -->
   <xsl:param name="tan:change-message" as="xs:string*" required="no"/>
   
   <!-- Is the application one of the core TAN applications? -->
   <xsl:param name="tan:stylesheet-is-core-tan-application" as="xs:boolean?" select="false()" required="no"/>
   
   <!-- What is the change history of the stylesheet? -->
   <xsl:param name="tan:stylesheet-change-log" as="element(tan:change)*" required="no"/>
   
   <!-- What remains to be done to the stylesheet? -->
   <xsl:param name="tan:stylesheet-to-do-list" as="element(tan:to-do)?" required="no"/>
   
   
   
   

</xsl:stylesheet>
