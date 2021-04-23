<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended URI functions. -->
   
   <xsl:function name="tan:absolutize-hrefs" as="item()*" visibility="public">
      <!-- Input: any items that should have urls converted to absolute URIs; a string representing the base uri -->
      <!-- Output: the items with each @href (also in processing instructions) and html:*/src resolved against the input base uri -->
      <xsl:param name="items-to-resolve" as="item()?"/>
      <xsl:param name="items-base-uri" as="xs:string"/>
      <xsl:apply-templates select="$items-to-resolve" mode="tan:revise-hrefs">
         <xsl:with-param name="original-url" select="$items-base-uri" tunnel="yes"/>
         <xsl:with-param name="make-absolute" tunnel="yes" select="true()" as="xs:boolean"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:function name="tan:revise-hrefs" as="item()*" visibility="public">
      <!-- Input: an item that should have urls resolved; the original url of the item; the target url (the item's destination) -->
      <!-- Output: the item with each @href (including those in processing instructions) and html:*/@src resolved -->
      <xsl:param name="items-to-resolve" as="item()?"/>
      <xsl:param name="items-original-url" as="xs:string"/>
      <xsl:param name="items-destination-url" as="xs:string"/>
      <xsl:variable name="original-url-resolved" select="resolve-uri($items-original-url)"/>
      <xsl:variable name="destination-url-resolved" select="resolve-uri($items-destination-url)"/>
      <xsl:if test="not($items-original-url = $original-url-resolved)">
         <xsl:message select="'tan:revise-hrefs() warning: param 2 url, ', $items-original-url, ', does not match resolved state: ', $original-url-resolved"/>
      </xsl:if>
      <xsl:if test="not($items-destination-url = $destination-url-resolved) and not(not($items-original-url = $original-url-resolved))">
         <xsl:message select="'tan:revise-hrefs() warning: param 3 url, ', $items-destination-url, ', does not match resolved state: ', $destination-url-resolved"/>
      </xsl:if>
      <xsl:apply-templates select="$items-to-resolve" mode="tan:revise-hrefs">
         <xsl:with-param name="original-url" select="$items-original-url" tunnel="yes"/>
         <xsl:with-param name="target-url" select="$items-destination-url" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:revise-hrefs" on-no-match="shallow-copy"/>
   
   <xsl:template match="processing-instruction()" priority="1" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>

      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:variable name="new-pi-content" as="xs:string*">
         <xsl:analyze-string select="." regex="{$href-regex}">
            <xsl:matching-substring>
               <xsl:variable name="this-replacement" as="xs:string" select="
                     if ($make-absolute) then
                        resolve-uri(regex-group(2), $original-url)
                     else
                        tan:uri-relative-to(resolve-uri(regex-group(2), $original-url), $target-url)"/>
               <xsl:value-of select="regex-group(1) || $this-replacement || regex-group(3)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>

      </xsl:variable>
      
      <xsl:processing-instruction name="{name(.)}" select="$new-pi-content"/>
   </xsl:template>
   
   <xsl:template match="@href" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>
      
      <xsl:variable name="this-href-resolved" select="resolve-uri(., $original-url)" as="xs:string"
      />
      <xsl:variable name="this-href-relative" as="xs:string"
         select="
            if ($make-absolute) then
               $this-href-resolved
            else
               tan:uri-relative-to($this-href-resolved, $target-url)"/>
      <xsl:choose>
         <xsl:when test="matches(., '^#')">
            <xsl:copy/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:attribute name="href" select="$this-href-relative"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="html:script/@src" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>
      <xsl:attribute name="src" select="
            if ($make-absolute) then
               resolve-uri(., $original-url)
            else
               tan:uri-relative-to(resolve-uri(., $original-url), $target-url)"/>
   </xsl:template>
   
   
   <xsl:function name="tan:parse-urls" as="element()*" visibility="public">
      <!-- Input: any sequence of strings -->
      <!-- Output: one element per string, parsed into children <non-url> and <url> -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:for-each select="$input-strings">
         <string>
            <xsl:analyze-string select="." regex="{$tan:url-regex}">
               <xsl:matching-substring>
                  <url>
                     <xsl:value-of select="."/>
                  </url>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <non-url>
                     <xsl:value-of select="."/>
                  </non-url>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </string>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:get-uuid" visibility="public">
      <!-- zero-param version of the full one -->
      <xsl:sequence select="tan:get-uuid(1)"/>
   </xsl:function>
   
   <xsl:function name="tan:get-uuid" as="xs:string*" visibility="public">
      <!-- Input: a digit -->
      <!-- Output: that digit's quantity of UUIDs -->
      <!-- Code courtesy D. Novatchev, https://stackoverflow.com/questions/8126963/xslt-generate-uuid/64792196#64792196 -->
      <xsl:param name="quantity" as="xs:integer"/>
      <xsl:sequence select="
            for $i in 1 to $quantity
            return
               unparsed-text('https://uuidgen.org/api/v/4?x=' || $i)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:relativize-hrefs" as="item()*">
      <!-- Input: any items; a resolved base uri (target) -->
      <!-- Output: the items, with links in standard attributes such as @href changed so as
         to be relative to the target base uri. -->
      <!-- This function is intended to serve output that is going to a particular destination,
      and that needs to have links to nearby resources revised to their relative form. -->
      <xsl:param name="input-items" as="item()*"/>
      <xsl:param name="target-base-uri-resolved" as="xs:string"/>
      
      <xsl:choose>
         <xsl:when test="tan:uri-is-relative($target-base-uri-resolved)">
            <xsl:message
               select="'Items returned unchanged because target base uri is not resolved. Fix: ' || $target-base-uri-resolved"
            />
            <xsl:sequence select="$input-items"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$input-items" mode="tan:relativize-hrefs">
               <xsl:with-param name="target-base-uri-resolved" select="$target-base-uri-resolved" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:relativize-hrefs" on-no-match="shallow-copy"/>
   
   <xsl:template match="processing-instruction()" mode="tan:relativize-hrefs">
      <xsl:param name="target-base-uri-resolved" required="yes" as="xs:string" tunnel="yes"/>
      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:processing-instruction name="{name(.)}">
            <xsl:analyze-string select="." regex="{$href-regex}">
                <xsl:matching-substring>
                   <xsl:choose>
                      <xsl:when test="tan:uri-is-resolved(regex-group(2))">
                        <xsl:value-of select="regex-group(1) || tan:uri-relative-to(regex-group(2), $target-base-uri-resolved) || regex-group(3)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="."/>
                      </xsl:otherwise>
                   </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:processing-instruction>
   </xsl:template>
   
   <xsl:template match="@href | html:script/@src" mode="tan:relativize-hrefs">
      <xsl:param name="target-base-uri-resolved" required="yes" as="xs:string" tunnel="yes"/>
      <xsl:attribute name="{name(.)}" select="
            if (tan:uri-is-resolved(.)) then
               tan:uri-relative-to(., $target-base-uri-resolved)
            else
               ."/>
   </xsl:template>
   

</xsl:stylesheet>
