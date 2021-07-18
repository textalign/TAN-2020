<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library standard numeric functions. -->
   
   <xsl:function name="tan:numbers-to-portions" as="xs:decimal*" visibility="public">
      <!-- Input: a sequence of numbers, representing a sequence of quantities of all the parts of a whole -->
      <!-- Output: one double per number, from 0 to 1, reflecting where each finishes in the sequence proportionate to the sum of the whole. 
      The last item always returns 1. Anything not castable to a double will be given the empty sequence. -->
      <xsl:param name="numbers" as="item()*"/>
      <xsl:variable name="this-sum" select="
         sum(for $i in $numbers[. castable as xs:double]
         return
         number($i))" as="xs:double?"/>
      <xsl:iterate select="$numbers">
         <xsl:param name="last-portion-end" as="xs:double" select="0"/>
         <xsl:variable name="this-is-castable-as-double" select=". castable as xs:double" as="xs:boolean"/>
         <xsl:variable name="this-double" as="xs:double" select="
               if ($this-is-castable-as-double) then
                  xs:double(.)
               else
                  0"/>
         <xsl:variable name="new-portion-end" select="$this-double + $last-portion-end" as="xs:double"/>
         <xsl:choose>
            <xsl:when test="$this-is-castable-as-double">
               <xsl:sequence select="xs:decimal($new-portion-end div $this-sum)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="()"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:next-iteration>
            <xsl:with-param name="last-portion-end" as="xs:double" select="$new-portion-end"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>
   
   
   <xsl:function name="tan:log2" as="xs:double?">
      <!-- Input: any double -->
      <!-- Output: the binary logarithm of the value -->
      <xsl:param name="arg" as="xs:double?"/>
      <xsl:sequence select="math:log($arg) div math:log(2)"/>
   </xsl:function>
   
   
   
</xsl:stylesheet>
