<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   version="3.0">
   <!-- This stylesheet is to hold core values and operations to assist the Schematron validation 
      unit for testing TAN applications. -->
   
   <xsl:variable name="tan:standard-app-preamble" as="xs:string">This is the public interface for
      the application. The code that runs the application can be found by following the links in the
      &lt;xsl:include> or &lt;xsl:import> at the bottom of this file. You are invited to alter as
      you like any of the parameters in this file, to customize the application to suit your needs.
      If you are relatively new to XSLT, or you are nervous about making changes, make a copy of
      this file before changing it, or configure a transformation scenario in Oxygen. If you are
      comfortable with XSLT, try creating your own stylesheet, then import this one, selectively
      changing the parameters as needed. </xsl:variable>
   <xsl:variable name="tan:standard-app-preamble-norm" as="xs:string" select="normalize-space($tan:standard-app-preamble)"/>
   <xsl:variable name="tan:standard-app-preamble-comment" as="comment()" select="tan:text-to-comment($tan:standard-app-preamble-norm, 2, 4, 100)"/>
   
   <xsl:function name="tan:text-to-comment" as="comment()">
      <xsl:param name="input-text" as="xs:string"/>
      <xsl:param name="depth-of-hierarchy" as="xs:integer"/>
      <xsl:param name="space-count" as="xs:integer"/>
      <xsl:param name="maximum-column-count" as="xs:integer"/>
      
      <xsl:variable name="new-line-indentation" as="xs:string" select="
            string-join(for $i in (1 to $depth-of-hierarchy),
               $j in (1 to $space-count)
            return
               ' ')"/>
      <xsl:variable name="column-width" as="xs:integer" select="$maximum-column-count - ($depth-of-hierarchy * $space-count)"/>
      <xsl:variable name="message-text-rewrapped" as="xs:string*">
         <xsl:iterate select="tokenize(normalize-space($input-text), ' ')">
            <xsl:param name="current-pos" select="2"/>
            <xsl:variable name="current-word-length" as="xs:integer" select="string-length(.)"/>
            <xsl:variable name="is-overrun" as="xs:boolean"
               select="$current-pos + $current-word-length gt $column-width"/>
            <xsl:variable name="next-pos" as="xs:integer" select="
                  if ($is-overrun) then
                     $current-word-length
                  else
                     ($current-pos + $current-word-length + 1)"/>

            <xsl:choose>
               <xsl:when test="$is-overrun">
                  <xsl:value-of select="'&#xa;' || $new-line-indentation || ."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="' ' || ."/>
               </xsl:otherwise>
            </xsl:choose>

            <xsl:next-iteration>
               <xsl:with-param name="current-pos" select="$next-pos"/>
            </xsl:next-iteration>
         </xsl:iterate>

      </xsl:variable>
      
      <xsl:comment><xsl:value-of select="string-join($message-text-rewrapped)"/></xsl:comment>
   </xsl:function>
</xsl:stylesheet>