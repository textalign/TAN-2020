<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended map functions. -->
   
   <xsl:function name="tan:map-put" as="map(*)" visibility="public">
      <!-- 2-parameter function of the supporting one below, but the 2nd parameter is a map of 
      replacements. -->
      <xsl:param name="map" as="map(*)"/>
      <xsl:param name="put-map" as="map(*)"/>
      
      <xsl:variable name="put-map-keys" select="map:keys($put-map)"/>
      <xsl:iterate select="$put-map-keys">
         <xsl:param name="map-so-far" as="map(*)" select="$map"/>
         <xsl:on-completion>
            <xsl:sequence select="$map-so-far"/>
         </xsl:on-completion>
         <xsl:variable name="new-map" select="tan:map-put($map-so-far, ., map:get($put-map, .))"/>
         <xsl:next-iteration>
            <xsl:with-param name="map-so-far" select="$new-map"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>
   
   <xsl:function name="tan:map-put" as="map(*)" visibility="public">
      <!-- Input: a map, an atomic type representing a key, and any items, representing the value -->
      <!-- Output: the input map, but with a new map entry. If a key exists already in the map, 
         the new entry is placed in the first appropriate place, otherwise it is added as a topmost
         map entry.
      -->
      <!-- This function parallels map:put(), but allows for deep placement of entries. This function
      was written to support changing values in a map for transform(), which has submaps that might need
      to be altered. -->
      <xsl:param name="map" as="map(*)"/>
      <xsl:param name="key" as="xs:anyAtomicType"/>
      <xsl:param name="value" as="item()*"/>
      <xsl:variable name="corresponding-entry" as="array(*)" select="map:find($map, $key)"/>
      <xsl:variable name="has-entry" select="array:size($corresponding-entry) gt 0"/>
      <xsl:choose>
         <xsl:when test="$has-entry">
            <xsl:sequence select="tan:map-put-loop($map, $key, $value)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="map:put($map, $key, $value)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:map-put-loop" visibility="private" as="map(*)">
      <!-- supporting loop function for tan:map-put() -->
      <!-- The order of map entries is implementation-dependent, so there is no "first" matching
      entry -->
      <xsl:param name="source-map" as="map(*)"/>
      <xsl:param name="target-key" as="xs:anyAtomicType"/>
      <xsl:param name="replacement-value" as="item()*"/>
      <xsl:variable name="current-map-keys" select="map:keys($source-map)"/>
      <xsl:map>
         <xsl:iterate select="$current-map-keys">
            <xsl:variable name="is-target-key" select="deep-equal(., $target-key)"/>
            <xsl:variable name="these-value-items" select="map:get($source-map, .)"/>
            <xsl:variable name="this-has-target-key"
               select="array:size(map:find($these-value-items, $target-key)) gt 0"/>
            <xsl:choose>
               <xsl:when test="not($is-target-key or $this-has-target-key)">
                  <xsl:map-entry key="." select="$these-value-items"/>
               </xsl:when>
               <xsl:when test="$is-target-key">
                  <xsl:map-entry key="." select="$replacement-value"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:map-entry key=".">
                     <xsl:iterate select="$these-value-items">
                        <xsl:variable name="this-search" select="map:find(., $target-key)"/>
                        <xsl:variable name="this-has-key" select="array:size($this-search) gt 0"/>
                        <xsl:choose>
                           <xsl:when test="$this-has-key">
                              <xsl:sequence select="tan:map-put-loop(., $target-key, $replacement-value)"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence select="."/>
                           </xsl:otherwise>
                        </xsl:choose>
                        <xsl:next-iteration/>
                     </xsl:iterate>
                  </xsl:map-entry>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:next-iteration/>
         </xsl:iterate>
      </xsl:map>
   </xsl:function>
   
   
   

</xsl:stylesheet>
