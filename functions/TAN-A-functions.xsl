<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
   version="2.0">

   <!-- Core functions for TAN-A files. Written principally for Schematron validation, but suitable for general use in other contexts -->

   <xsl:include href="incl/TAN-class-1-functions.xsl"/>
   <xsl:include href="incl/TAN-class-2-functions.xsl"/>
   <xsl:include href="incl/TAN-class-3-functions.xsl"/>
   <xsl:include href="incl/TAN-core-functions.xsl"/>

   <!-- GLOBAL VARIABLES -->

   <xsl:variable name="subjects-target-what-elements-names"
      select="$id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@attribute = 'subject']]/tan:element"/>
   <xsl:variable name="objects-target-what-elements-names"
      select="$id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@attribute = 'object']]/tan:element"/>
   <xsl:variable name="datatypes-that-require-unit-specification" as="xs:string+" select="('decimal', 'float', 'double', 'integer', 'nonPositiveInteger', 'negativeInteger', 'long', 'nonNegativeInteger', 'positiveInteger')"/>

   <!-- FUNCTIONS -->

   <xsl:function name="tan:data-type-check" as="xs:boolean">
      <!-- Input: an item and a string naming a data type -->
      <!-- Output: a boolean indicating whether the item can be cast into that data type -->
      <!-- If the first parameter doesn't match a data type, the function returns false -->
      <xsl:param name="item" as="item()?"/>
      <xsl:param name="data-type" as="xs:string"/>
      <xsl:choose>
         <xsl:when test="$data-type = 'string'">
            <xsl:value-of select="$item castable as xs:string"/>
         </xsl:when>
         <xsl:when test="$data-type = 'boolean'">
            <xsl:value-of select="$item castable as xs:boolean"/>
         </xsl:when>
         <xsl:when test="$data-type = 'decimal'">
            <xsl:value-of select="$item castable as xs:decimal"/>
         </xsl:when>
         <xsl:when test="$data-type = 'float'">
            <xsl:value-of select="$item castable as xs:float"/>
         </xsl:when>
         <xsl:when test="$data-type = 'double'">
            <xsl:value-of select="$item castable as xs:double"/>
         </xsl:when>
         <xsl:when test="$data-type = 'duration'">
            <xsl:value-of select="$item castable as xs:duration"/>
         </xsl:when>
         <xsl:when test="$data-type = 'dateTime'">
            <xsl:value-of select="$item castable as xs:dateTime"/>
         </xsl:when>
         <xsl:when test="$data-type = 'time'">
            <xsl:value-of select="$item castable as xs:time"/>
         </xsl:when>
         <xsl:when test="$data-type = 'date'">
            <xsl:value-of select="$item castable as xs:date"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gYearMonth'">
            <xsl:value-of select="$item castable as xs:gYearMonth"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gYear'">
            <xsl:value-of select="$item castable as xs:gYear"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gMonthDay'">
            <xsl:value-of select="$item castable as xs:gMonthDay"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gDay'">
            <xsl:value-of select="$item castable as xs:gDay"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gMonth'">
            <xsl:value-of select="$item castable as xs:gMonth"/>
         </xsl:when>
         <xsl:when test="$data-type = 'hexBinary'">
            <xsl:value-of select="$item castable as xs:hexBinary"/>
         </xsl:when>
         <xsl:when test="$data-type = 'base64Binary'">
            <xsl:value-of select="$item castable as xs:base64Binary"/>
         </xsl:when>
         <xsl:when test="$data-type = 'anyURI'">
            <xsl:value-of select="$item castable as xs:anyURI"/>
         </xsl:when>
         <xsl:when test="$data-type = 'QName'">
            <xsl:value-of select="$item castable as xs:QName"/>
         </xsl:when>
         <!-- the following datatypes are not recognized in a basic XSLT 2.0 processor; code is retained for future development -->
         <!--<xsl:when test="$data-type = 'normalizedString'">
            <xsl:value-of select="$item castable as xs:normalizedString"/>
         </xsl:when>
         <xsl:when test="$data-type = 'token'">
            <xsl:value-of select="$item castable as xs:token"/>
         </xsl:when>
         <xsl:when test="$data-type = 'language'">
            <xsl:value-of select="$item castable as xs:language"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NMTOKEN'">
            <xsl:value-of select="$item castable as xs:NMTOKEN"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NMTOKENS'">
            <xsl:value-of select="$item castable as xs:NMTOKENS"/>
         </xsl:when>
         <xsl:when test="$data-type = 'Name'">
            <xsl:value-of select="$item castable as xs:Name"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NCName'">
            <xsl:value-of select="$item castable as xs:NCName"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ID'">
            <xsl:value-of select="$item castable as xs:ID"/>
         </xsl:when>
         <xsl:when test="$data-type = 'IDREF'">
            <xsl:value-of select="$item castable as xs:IDREF"/>
         </xsl:when>
         <xsl:when test="$data-type = 'IDREFS'">
            <xsl:value-of select="$item castable as xs:IDREFS"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ENTITY'">
            <xsl:value-of select="$item castable as xs:ENTITY"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ENTITIES'">
            <xsl:value-of select="$item castable as xs:ENTITIES"/>
         </xsl:when>
         <xsl:when test="$data-type = 'integer'">
            <xsl:value-of select="$item castable as xs:integer"/>
         </xsl:when>
         <xsl:when test="$data-type = 'nonPositiveInteger'">
            <xsl:value-of select="$item castable as xs:nonPositiveInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'negativeInteger'">
            <xsl:value-of select="$item castable as xs:negativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'long'">
            <xsl:value-of select="$item castable as xs:long"/>
         </xsl:when>
         <xsl:when test="$data-type = 'int'">
            <xsl:value-of select="$item castable as xs:int"/>
         </xsl:when>
         <xsl:when test="$data-type = 'short'">
            <xsl:value-of select="$item castable as xs:short"/>
         </xsl:when>
         <xsl:when test="$data-type = 'byte'">
            <xsl:value-of select="$item castable as xs:byte"/>
         </xsl:when>
         <xsl:when test="$data-type = 'nonNegativeInteger'">
            <xsl:value-of select="$item castable as xs:nonNegativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedLong'">
            <xsl:value-of select="$item castable as xs:unsignedLong"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedInt'">
            <xsl:value-of select="$item castable as xs:unsignedInt"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedShort'">
            <xsl:value-of select="$item castable as xs:unsignedShort"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedByte'">
            <xsl:value-of select="$item castable as xs:unsignedByte"/>
         </xsl:when>
         <xsl:when test="$data-type = 'positiveInteger'">
            <xsl:value-of select="$item castable as xs:positiveInteger"/>
         </xsl:when>-->
         <!-- some workarounds for the above -->
         <xsl:when test="$data-type = 'IDREF'">
            <xsl:value-of select="count(root($item)//id($item)) = 1"/>
         </xsl:when>
         <xsl:when test="$data-type = 'IDREFS'">
            <xsl:value-of select="exists(root($item)//id($item))"/>
         </xsl:when>
         <xsl:when test="$data-type = 'language'">
            <xsl:value-of select="matches($item, '^[a-z]{2,3}(-[A-Z]{2,3}(-[a-zA-Z]{4})?)?$')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="false()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- PROCESSING TAN-A FILES: RESOLUTION -->
   
   <xsl:template match="tan:body" mode="imprint-vocabulary" priority="1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <!-- PROCESSING TAN-A FILES: EXPANSION -->

   <!-- TERSE EXPANSION -->

   <!-- TAN-A files have one idref that cannot be fully resolved in the traditional resolve phase, and that's taking care
      of @work. We rectify that by building <work> vocabulary and (1) copying it to the <vocabulary-key> and (2) passing
      it to every claim's <work> to copy all aliases.
   -->
   <xsl:template match="/" mode="core-expansion-terse">
      <xsl:param name="dependencies" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-head" select="tan:TAN-A/tan:head"/>
      <xsl:variable name="token-definition-source-duplicates"
         select="tan:duplicate-items(tan:token-definition/tan:src)"/>
      <xsl:variable name="work-elements-pass-1" as="element()*">
         <xsl:for-each select="$dependencies/*/tan:head/tan:work">
            <xsl:variable name="this-src" select="/*/@src"/>
            <xsl:variable name="attr-which-vocabulary" select="tan:attribute-vocabulary(@which)"/>
            <xsl:variable name="this-vocabulary-item"
               select="
                  if (exists(tan:IRI)) then
                     .
                  else
                     $attr-which-vocabulary/tan:item"
            />
            <xsl:variable name="these-equate-works"
               select="$this-head/tan:vocabulary-key/tan:alias[tan:idref = $this-src]"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:for-each select="$this-vocabulary-item/(tan:IRI, tan:name)">
                  <xsl:copy>
                     <xsl:copy-of select="@norm, @xml:lang"/>
                     <xsl:value-of select="."/>
                  </xsl:copy>
               </xsl:for-each>
               <id>
                  <xsl:value-of select="$this-src"/>
               </id>
               <xsl:for-each select="$these-equate-works/tan:idref">
                  <id>
                     <xsl:value-of select="."/>
                  </id>
               </xsl:for-each>
               <xsl:copy-of select="$these-equate-works/tan:alias"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="work-elements-pass-2" as="element()*"
         select="tan:group-elements-by-shared-node-values($work-elements-pass-1, 'IRI|id')"/>
      <xsl:variable name="work-elements-pass-3" as="element()*">
         <xsl:apply-templates select="$work-elements-pass-2" mode="#current"/>
      </xsl:variable>
       <xsl:variable name="these-vocab-items" select="$this-head/tan:vocabulary/tan:item"/>
      <xsl:variable name="work-elements-to-integrate-with-existing-vocab-items" select="$work-elements-pass-3[tan:IRI = $these-vocab-items/tan:IRI]"/>
      <xsl:variable name="work-elements-to-add-as-new-vocab-items" select="$work-elements-pass-3 except $work-elements-to-integrate-with-existing-vocab-items"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode core-expansion-terse() for TAN-A document node'"/>
         <xsl:message select="'token definition source duplicates: ', $token-definition-source-duplicates"/>
         <xsl:message select="'work elements pass 1: ', $work-elements-pass-1"/>
         <xsl:message select="'work elements pass 2: ', $work-elements-pass-2"/>
         <xsl:message select="'work elements pass 3: ', $work-elements-pass-3"/>
         <xsl:message select="'work elements to integrate with existing vocab items: ', $work-elements-to-integrate-with-existing-vocab-items"/>
         <xsl:message select="'work elements to add as new vocab items: ', $work-elements-to-add-as-new-vocab-items"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="extra-vocabulary"
               select="$work-elements-to-add-as-new-vocab-items" tunnel="yes"/>
            <!-- vocab to integrate gets picked up in the check-referred-doc template just below -->
            <xsl:with-param name="vocabulary-to-integrate" tunnel="yes"
               select="$work-elements-to-integrate-with-existing-vocab-items"/>
            <xsl:with-param name="token-definition-errors"
               select="$token-definition-source-duplicates"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:claim/tan:work | tan:object/tan:work | tan:subject/tan:work"
      mode="core-expansion-terse">
      <!-- This template targets <work> elements in the body, not the head -->
      <!-- Such a step would ordinarily have been taken in the previous expansion pass,
      on attributes, but it didn't have the extra vocabulary. -->
      <xsl:param name="extra-vocabulary" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-work-id" select="."/>
      <xsl:variable name="this-vocab"
         select="$extra-vocabulary[self::tan:work][(tan:id | tan:name | tan:alias) = $this-work-id]"/>

      <xsl:choose>
         <xsl:when test="exists($this-vocab)">
            <xsl:for-each select="$this-vocab/tan:id">
               <work attr="">
                  <xsl:value-of select="."/>
               </work>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary/tan:item" priority="2" mode="check-referred-doc">
      <!-- This template overrides the one in TAN-core-expand-functions.xsl -->
      <xsl:param name="vocabulary-to-integrate" tunnel="yes" as="element()*"/>
      <xsl:variable name="these-iris" select="tan:IRI"/>
      <xsl:variable name="this-vocabulary-to-integrate" select="$vocabulary-to-integrate[tan:IRI = $these-iris]"/>
      <xsl:variable name="these-nodes" select="node()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($this-vocabulary-to-integrate)">
               <xsl:copy-of select="tan:distinct-items((node(), $this-vocabulary-to-integrate/node()))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:group[tan:work]" mode="core-expansion-terse">
      <work>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:distinct-items(tan:work/*)"/>
      </work>
   </xsl:template>

   <xsl:template match="tan:body" mode="core-expansion-terse">
      <xsl:variable name="this-vocabulary"
         select="preceding-sibling::tan:head/(tan:vocabulary-key, tan:tan-vocabulary, tan:vocabulary)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="vocabulary" select="$this-vocabulary" tunnel="yes"/>
            <xsl:with-param name="inherited-subjects" select="tan:subject" tunnel="yes"/>
            <xsl:with-param name="inherited-verbs" select="tan:verb" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:claim" mode="core-expansion-terse">
      <!-- subjects and verbs are the only two elements of a claim that are inheritable, since they are the only ones expected to be the basis for grouping claims -->
      <xsl:param name="inherited-subjects" tunnel="yes"/>
      <xsl:param name="inherited-verbs" tunnel="yes"/>
      <xsl:variable name="vocabulary-parents" select="root()/*/*"/>
      <xsl:variable name="immediate-subject-refs" select="tan:subject"/>
      <xsl:variable name="immediate-verb-refs" select="tan:verb/text()"/>

      <!-- subjects -->
      <xsl:variable name="these-subject-refs"
         select="
            if (exists($immediate-subject-refs)) then
               $immediate-subject-refs
            else
               $inherited-subjects"/>
      <xsl:variable name="these-entity-subject-refs" select="$these-subject-refs[@attr]/text(), $these-subject-refs/(@work, @src, @scriptum, @which)"/>
      <xsl:variable name="these-textual-passage-subject-refs"
         select="$these-subject-refs[@ref]"/>
      <xsl:variable name="this-entity-subject-vocab"
         select="
            for $i in $these-entity-subject-refs
            return
               tan:vocabulary($subjects-target-what-elements-names, $i, $vocabulary-parents)"/>
      <xsl:variable name="these-entity-subject-vocab-items"
         select="$this-entity-subject-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="these-subject-textual-entities"
         select="$these-entity-subject-vocab-items[(name(.), tan:affects-element) = $names-of-elements-that-describe-textual-entities]"/>
      <xsl:variable name="these-subject-nontextual-entities"
         select="$these-entity-subject-vocab-items except $these-subject-textual-entities"/>
      <xsl:variable name="these-subject-textual-artefact-entities"
         select="$these-subject-textual-entities[(name(.), tan:affects-element) = $names-of-elements-that-describe-text-bearers]"/>
      <xsl:variable name="these-subject-nontextual-artefact-entities"
         select="$these-entity-subject-vocab-items except $these-subject-textual-artefact-entities"/>

      <!-- verbs -->
      <xsl:variable name="these-verb-refs"
         select="
            if (exists($immediate-verb-refs)) then
               $immediate-verb-refs
            else
               $inherited-verbs"/>
      <xsl:variable name="this-verb-vocab"
         select="
            for $i in $these-verb-refs
            return
               tan:vocabulary('verb', $i, $vocabulary-parents)"
      />
      <xsl:variable name="these-verb-vocab-items"
         select="$this-verb-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="verbs-that-disallow-subjects" select="$these-verb-vocab-items[tan:constraints/tan:subject/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-subjects" select="$these-verb-vocab-items[tan:constraints/tan:subject/@status = 'required' or not(exists(tan:constraints/tan:subject))]"/>
      <xsl:variable name="verbs-that-disallow-objects" select="$these-verb-vocab-items[tan:constraints/tan:object/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-objects" select="$these-verb-vocab-items[tan:constraints/tan:object/@status = 'required' or not(exists(tan:constraints/tan:object))]"/>
      <xsl:variable name="verbs-expecting-subject-content-units" select="$these-verb-vocab-items[tan:constraints/tan:subject/@content-datatype = $datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbs-expecting-object-content-units" select="$these-verb-vocab-items[tan:constraints/tan:object/@content-datatype = $datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbs-that-disallow-at-ref" select="$these-verb-vocab-items[tan:constraints/tan:at-ref/@status = 'disallowed' or not(exists(tan:constraints/tan:at-ref))]"/>
      <xsl:variable name="verbs-that-require-at-ref" select="$these-verb-vocab-items[tan:constraints/tan:at-ref/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-in-lang" select="$these-verb-vocab-items[tan:constraints/tan:in-lang/@status = 'disallowed' or not(exists(tan:constraints/tan:in-lang))]"/>
      <xsl:variable name="verbs-that-require-in-lang" select="$these-verb-vocab-items[tan:constraints/tan:in-lang/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-period" select="$these-verb-vocab-items[tan:constraints/tan:period/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-period" select="$these-verb-vocab-items[tan:constraints/tan:period/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-place" select="$these-verb-vocab-items[tan:constraints/tan:place/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-place" select="$these-verb-vocab-items[tan:constraints/tan:place/@status = 'required']"/>
      


      <xsl:variable name="these-verbs-with-general-constraints"
         select="$these-verb-vocab-items[tan:group]"/>
      <xsl:variable name="these-verbs-with-data-for-object"
         select="$these-verb-vocab-items[@object-datatype]"/>
      <xsl:variable name="these-verbs-whose-objects-require-unit-specification"
         select="$these-verb-vocab-items[@object-datatype = $datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbal-groups" select="$these-verbs-with-general-constraints/tan:group"/>


      <!-- objects -->
      <xsl:variable name="these-object-refs" select="(tan:object, tan:claim)"/>
      <xsl:variable name="these-entity-object-refs" select="$these-object-refs[@attr]"/>
      <xsl:variable name="these-textual-passage-object-refs"
         select="$these-object-refs[tan:src or tan:work]"/>
      <xsl:variable name="this-entity-object-vocab"
         select="
            for $i in $these-entity-object-refs
            return
               tan:vocabulary($objects-target-what-elements-names, $i, $vocabulary-parents)"
      />
      <xsl:variable name="these-entity-object-vocab-items"
         select="$this-entity-object-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="these-object-textual-entities"
         select="$these-entity-object-vocab-items[(name(.), tan:affects-element) = $names-of-elements-that-describe-textual-entities]"/>
      <xsl:variable name="these-object-nontextual-entities"
         select="$these-entity-object-vocab-items except $these-object-textual-entities"/>
      <xsl:variable name="these-object-textual-artefact-entities" 
         select="$these-object-textual-entities[(name(.), tan:affects-element) = $names-of-elements-that-describe-text-bearers]"/>
      <xsl:variable name="these-object-nontextual-artefact-entities"
         select="$these-entity-object-vocab-items except $these-object-textual-artefact-entities"/>
      <xsl:variable name="these-data-object-refs"
         select="$these-object-refs except ($these-entity-object-refs, $these-textual-passage-object-refs)"/>


      <!-- at-refs -->
      <xsl:variable name="these-at-refs" select="tan:at-ref"/>
      
      <!-- special elements that must be explicitly allowed -->
      <!-- in-lang -->
      <xsl:variable name="these-in-langs" select="tan:in-lang"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode core-expansion-terse, for: ', ."/>
         <xsl:message select="'subjects inherited: ', $inherited-subjects"/>
         <xsl:message select="'subjects: entities: ', $these-entity-subject-vocab-items"/>
         <xsl:message select="'subjects: textual passages: ', $these-textual-passage-subject-refs"/>
         <xsl:message select="'verbs inherited: ', $inherited-verbs"/>
         <xsl:message select="'verb refs actual: ', $these-verb-refs"/>
         <xsl:message select="'verb vocab items: ', $these-verb-vocab-items"/>
         <xsl:message
            select="'verbs with object constraints: ', $these-verbs-whose-objects-require-unit-specification"/>
         <xsl:message select="'verbal groups: ', $verbal-groups"/>
         <xsl:message select="'objects: entities: ', $these-entity-object-vocab-items"/>
         <xsl:message select="'objects: textual passages: ', $these-textual-passage-object-refs"/>
         <xsl:message select="'objects: data: ', $these-data-object-refs"/>
      </xsl:if>
      
      <xsl:variable name="errors-that-should-be-ignored"
         as="element()*">
         <xsl:if test="exists($these-verbs-with-data-for-object)">
            <xsl:sequence select="tan:error[*/tan:id = $these-data-object-refs]"/>
         </xsl:if>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         
         <!-- subject problems -->
         <xsl:if test="exists($verbs-expecting-subject-content-units) and exists($these-subject-refs[not(@units)])">
            <xsl:copy-of select="tan:error('clm01')"/>
         </xsl:if>
         <xsl:if test="$these-verb-vocab-items[tan:constraints/tan:subject/@content-datatype] and (count($these-verb-vocab-items) gt 1)">
            <xsl:copy-of select="tan:error('clm02')"/>
         </xsl:if>
         <xsl:if test="not(exists($these-subject-refs)) and exists($verbs-that-require-subjects)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-subjects/tan:name[1], ', '), ' requires a subject'))"/>
         </xsl:if>
         <xsl:if test="exists($these-subject-refs) and exists($verbs-that-disallow-subjects)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-disallow-subjects/tan:name[1], ', '), ' disallow a subject'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-subjects) and exists($verbs-that-require-subjects)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-subjects/tan:name[1], ', '), ' must not have subjects; the verb ', string-join($verbs-that-require-subjects/tan:name[1], ', '), ' must have them'))"
            />
         </xsl:if>

         <!-- verb problems -->
         <!-- verb data constraint problems -->
         <xsl:if test="exists($these-verbs-whose-objects-require-unit-specification)">
            <!-- if data is expected, no object should be an entity or a textual passage -->
            <xsl:if test="exists(tan:object[not(@units)])">
               <xsl:copy-of select="tan:error('clm01')"/>
            </xsl:if>
            <xsl:if test="count($these-verb-vocab-items) gt 1">
               <xsl:copy-of select="tan:error('clm02')"/>
            </xsl:if>
         </xsl:if>
         <xsl:if test="not(exists($these-verb-refs)) and not(exists(tan:claim))">
            <xsl:copy-of select="tan:error('clm07')"/>
         </xsl:if>
         
         
         <!-- object problems -->
         <xsl:if test="exists($verbs-expecting-object-content-units) and exists($these-object-refs[not(@units)])">
            <xsl:copy-of select="tan:error('clm01')"/>
         </xsl:if>
         <xsl:if test="$these-verb-vocab-items[tan:constraints/tan:object/@content-datatype] and (count($these-verb-vocab-items) gt 1)">
            <xsl:copy-of select="tan:error('clm02')"/>
         </xsl:if>
         <xsl:if test="not(exists($these-object-refs)) and exists($verbs-that-require-objects)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-objects/tan:name[1], ', '), ' must take an object'))"/>
         </xsl:if>
         <xsl:if test="exists($these-object-refs) and exists($verbs-that-disallow-objects)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-disallow-objects/tan:name[1], ', '), ' must not take an object'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-objects) and exists($verbs-that-require-objects)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-objects/tan:name[1], ', '), ' must not have objects; the verb ', string-join($verbs-that-require-objects/tan:name[1], ', '), ' must have them'))"
            />
         </xsl:if>
         
         <!-- other claim element problems -->
         <xsl:if test="exists($verbs-that-require-in-lang) and not(exists(tan:in-lang))">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-in-lang/tan:name[1], ', '), ' must have in-lang'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-in-lang) and exists(tan:in-lang)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-disallow-in-lang/tan:name[1], ', '), ' must not have in-lang'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-in-lang) and exists($verbs-that-disallow-in-lang)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-in-lang/tan:name[1], ', '), ' must not have in-lang; the verb ', string-join($verbs-that-require-in-lang/tan:name[1], ', '), ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-at-ref) and not(exists(tan:at-ref))">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-at-ref/tan:name[1], ', '), ' must have at-ref'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-at-ref) and exists(tan:at-ref)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-at-ref/tan:name[1], ', '), ' must not have at-ref'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-at-ref) and exists($verbs-that-disallow-at-ref)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-at-ref/tan:name[1], ', '), ' must not have at-ref; the verb ', string-join($verbs-that-require-at-ref/tan:name[1], ', '), ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-period) and not(exists(tan:period))">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-period/tan:name[1], ', '), ' must have period'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-period) and exists(tan:period)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-period/tan:name[1], ', '), ' must not have period'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-period) and exists($verbs-that-disallow-period)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-period/tan:name[1], ', '), ' must not have period; the verb ', string-join($verbs-that-require-period/tan:name[1], ', '), ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-place) and not(exists(tan:place))">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-place/tan:name[1], ', '), ' must have place'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-place) and exists(tan:place)">
            <xsl:copy-of select="tan:error('clm08', concat('The verb ', string-join($verbs-that-require-place/tan:name[1], ', '), ' must not have place'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-place) and exists($verbs-that-disallow-place)">
            <xsl:copy-of
               select="tan:error('clm09', concat('The verb ', string-join($verbs-that-disallow-place/tan:name[1], ', '), ' must not have place; the verb ', string-join($verbs-that-require-place/tan:name[1], ', '), ' must have it'))"
            />
         </xsl:if>
         
         <xsl:apply-templates select="node() except $errors-that-should-be-ignored" mode="#current">
            <xsl:with-param name="verbs" select="$these-verb-vocab-items"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:subject | tan:object" mode="core-expansion-terse">
      <xsl:param name="verbs" as="element()*"/>
      <xsl:variable name="vocabulary-parents" select="root()/*/*"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="target-element-names" select="tan:target-element-names($this-name)"/>
      <xsl:variable name="these-constraint-rules" select="$verbs/tan:constraints/*[name(.) = $this-name]"/>
      <xsl:variable name="these-content-constraints" select="$these-constraint-rules[exists(@content-datatype)]"/>
      <xsl:variable name="these-item-type-constraints" select="$these-constraint-rules[@item-type]"/>
      <xsl:variable name="this-text" select="normalize-space(string-join(text(), ''))"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-idref"
         select="
            if (exists(@attr)) then
               text()
            else
               (@which, @scriptum)"
      />
      <xsl:variable name="this-vocabulary"
         select="
            if (exists($this-idref)) then
               tan:vocabulary($target-element-names, $this-idref, $vocabulary-parents)
            else
               ()"
      />
      <xsl:variable name="target-element-names" as="xs:string*"
         select="
            for $i in $this-vocabulary/*[tan:IRI or self::tan:claim]
            return
               (name($i), $i/(tan:affects-element, tan:affects-attribute))"
      />
      <xsl:for-each select="$these-item-type-constraints">
         <xsl:variable name="these-types-allowed" select="tokenize(normalize-space(@item-type), ' ')"/>
         <xsl:variable name="ref-allowed-and-found" select="exists($this-ref) and $these-types-allowed = 'ref'"/>
         <xsl:variable name="acceptable-vocabulary" as="element()*"
            select="tan:vocabulary($these-types-allowed, '*', $vocabulary-parents)"/>
         <xsl:if test="not($these-types-allowed = '*') and not($ref-allowed-and-found) and not($these-types-allowed = $target-element-names)">
            <xsl:copy-of
               select="
                  tan:error('clm08', concat('Every ', $this-name, ' of the verb ', parent::tan:constraints/../tan:name[1], ' must be one of the following types: ',
                  string-join($these-types-allowed, ', '), if (exists($target-element-names)) then
                     concat('; ', $this-idref, ' is a ', string-join(distinct-values($target-element-names[not(. = 'item')]), ', '))
                  else
                     (), if (exists($acceptable-vocabulary)) then
                     (concat('; try: ', string-join($acceptable-vocabulary/*/(tan:id/text(), tan:name[1])[1], ', ')))
                  else
                     concat('; no vocabulary is available for ', string-join($these-types-allowed, ', '))))"
            />
         </xsl:if>
      </xsl:for-each>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(@units) and exists($these-constraint-rules[not(@content-datatype = $datatypes-that-require-unit-specification)])">
            <xsl:copy-of select="tan:error('clm05')"/>
         </xsl:if>
         <xsl:for-each select="$these-content-constraints">
            <xsl:variable name="this-datatype" select="@content-datatype"/>
            <xsl:variable name="this-lexical-constraint" select="@content-lexical-constraint"/>
            <xsl:if test="not(tan:data-type-check($this-text, $this-datatype))">
               <xsl:variable name="help-message"
                  select="concat('value must match data type ', $this-datatype)"/>
               <xsl:copy-of select="tan:error('clm03', $help-message)"/>
            </xsl:if>
            <xsl:if
               test="exists($this-lexical-constraint) and not(matches($this-text, $this-lexical-constraint))">
               <xsl:variable name="help-message"
                  select="concat('value must match pattern ', $this-lexical-constraint)"/>
               <xsl:copy-of select="tan:error('clm04', $help-message)"/>
            </xsl:if>
         </xsl:for-each>

         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>


   <!-- NORMAL EXPANSION -->

   <xsl:template match="tan:subject/tan:div | tan:object/tan:div" priority="1" mode="core-expansion-normal">
      <!-- This template prevents a <div> within a claim being treated as if part of a class 1 file. -->
      <xsl:copy-of select="."/>
   </xsl:template>

   <!-- VERBOSE EXPANSION -->

   <!-- pending -->

</xsl:stylesheet>
