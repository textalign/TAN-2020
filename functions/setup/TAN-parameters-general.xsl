<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- Core general parameters for the TAN function library. These parameters may be overwritten, but 
      TAN-static-parameters.xsl. For parameters that most users will likely wish to change, see the
      parameters subdirectory in the TAN project.
   -->

   <!-- If a TAN file is validated, should it be expanded tersely? Overwritten by a true value given to deeper validation 
      level. This value is treated as being true if both deeper validation levels are false. -->
   <xsl:param name="tan:validation-is-terse" as="xs:boolean" select="false()"/>
   <!-- If a TAN file is validated, should it be expanded normally? Overwritten by a true value given to deeper validation 
      level. -->
   <xsl:param name="tan:validation-is-normal" as="xs:boolean" select="false()"/>
   <!-- If a TAN file is validated, should it be expanded verbosely? -->
   <xsl:param name="tan:validation-is-verbose" as="xs:boolean" select="false()"/>

   <xsl:param name="tan:default-validation-phase" as="xs:string" select="
         if ($tan:validation-is-verbose)
         then
            'verbose'
         else
            if ($tan:validation-is-normal) then
               'normal'
            else
               'terse'"/>

</xsl:stylesheet>
