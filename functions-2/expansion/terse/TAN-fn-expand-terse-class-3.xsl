<xsl:stylesheet exclude-result-prefixes="#all"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library, terse expansion, class 3 files. -->
   
   <xsl:template match="tan:TAN-mor/tan:body[tan:category]" mode="tan:dependency-adjustments-pass-1 tan:core-expansion-terse">
      <xsl:variable name="duplicate-features" select="tan:duplicate-items(tan:category/tan:feature/tan:type)"/>
      <xsl:variable name="alias-ids" as="xs:string*" select="preceding-sibling::tan:head/tan:vocabulary-key/tan:alias/(@xml:id, @id)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-features" select="$duplicate-features" tunnel="yes"/>
            <xsl:with-param name="alias-ids" tunnel="yes" select="$alias-ids"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:category" mode="tan:dependency-adjustments-pass-1 tan:core-expansion-terse">
      <xsl:variable name="duplicate-codes" select="tan:duplicate-items(tan:feature/tan:code)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-codes" select="$duplicate-codes" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:feature/tan:type" mode="tan:dependency-adjustments-pass-1 tan:core-expansion-terse">
      <xsl:param name="duplicate-features" tunnel="yes"/>
      <xsl:param name="alias-ids" as="xs:string*" tunnel="yes"/>
      <xsl:if test=". = $alias-ids">
         <xsl:copy-of select="tan:error('tmo03', (. || ' is an alias id'))"/>
      </xsl:if>
      <xsl:if test=". = $duplicate-features">
         <xsl:copy-of select="tan:error('tmo01', (. || ' is repeated'))"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:feature/tan:code" mode="tan:dependency-adjustments-pass-1 tan:core-expansion-terse">
      <xsl:param name="duplicate-codes" tunnel="yes"/>
      <xsl:if test=". = $duplicate-codes">
         <xsl:copy-of select="tan:error('tmo02', (. || ' repeats'))"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:TAN-mor" mode="tan:mark-dependencies-pass-1 tan:mark-dependencies-pass-2">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   
   <!-- TAN-mor -->
   
   <xsl:template match="tan:TAN-mor/tan:head/tan:vocabulary-key/tan:feature[@which]/tan:id" priority="1" mode="tan:core-expansion-terse">
      <!-- This template overrules the default, which flags as erroneous any vocabulary item whose @xml:id repeats
         the value of @which. TAN-mor files must cite every feature that is allowed, and many times the @which value
         is conveniently also the perfect id. -->
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <!-- TAN-voc -->
   
   <xsl:template match="tan:TAN-voc/tan:body" mode="tan:core-expansion-terse">
      <xsl:variable name="all-body-iris" select=".//tan:IRI"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-IRIs" select="tan:duplicate-items($all-body-iris)"
               tunnel="yes"/>
            <xsl:with-param name="is-reserved"
               select="(parent::tan:TAN-voc/@id = $tan:TAN-vocabulary-files/*/@id) or $tan:doc-is-error-test"
               tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[@affects-element]/tan:affects-element" mode="tan:core-expansion-terse">
      <xsl:variable name="this-val" select="."/>
      <xsl:if test="not(. = $tan:names-of-elements-that-take-which)">
         <xsl:variable name="this-fix" as="element()*">
            <xsl:for-each select="$tan:names-of-elements-that-take-which">
               <xsl:sort select="matches(., $this-val)" order="descending"/>
               <element affects-element="{.}"/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:copy-of
            select="tan:error('voc03', ('try: ' || string-join($this-fix/@affects-element, ', ')), $this-fix, 'copy-attributes')"
         />
      </xsl:if>
      <xsl:if test="($this-val = 'vocabulary') and not(tan:doc-id-namespace(root(.)) = $tan:TAN-id-namespace)">
         <xsl:copy-of select="tan:error('voc06')"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:item | tan:verb" mode="tan:core-expansion-terse">
      <xsl:param name="is-reserved" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="these-affects-elements" select="tan:affects-element/text()"/>
      <xsl:variable name="reserved-vocabulary-docs"
         select="$tan:TAN-vocabularies[tan:TAN-voc/tan:body[tokenize(@affects-element, '\s+') = $these-affects-elements]]"/>
      <xsl:variable name="reserved-vocabulary-items"
         select="
         for $i in $reserved-vocabulary-docs
         return
         key('tan:item-via-node-name', $these-affects-elements, $i)"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="($is-reserved = true()) 
            and (not(exists(tan:IRI[starts-with(., $tan:TAN-id-namespace)]))) and (not(exists(tan:token-definition)))">
            <xsl:variable name="this-fix" as="element()">
               <IRI>
                  <xsl:value-of select="$tan:TAN-namespace"/>
               </IRI>
            </xsl:variable>
            <xsl:copy-of select="tan:error('voc04', (), $this-fix, 'prepend-content')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reserved-vocabulary-items" select="$reserved-vocabulary-items"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
      
</xsl:stylesheet>
