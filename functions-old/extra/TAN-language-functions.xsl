<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xhtml="http://www.w3.org/1999/xhtml"
   xmlns:mods="http://www.loc.gov/mods/v3"  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   exclude-result-prefixes="#all" version="3.0">
   <!-- This is a special set of extra functions for processing information about languages -->

   <xsl:variable name="iso-639-3" select="doc('lang/iso-639-3.xml')" as="document-node()?"/>
   
   <!-- GENERAL -->
   
   <xsl:function name="tan:lang-code" as="xs:string*">
      <!-- Input: the name of a language -->
      <!-- Output: the 3-letter code for the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <xsl:param name="lang-name" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$iso-639-3/tan:iso-639-3/tan:l[@name = $lang-name]/@id"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-name) gt 0)">
            <xsl:value-of
               select="
                  for $i in $iso-639-3/tan:iso-639-3/tan:l[matches(@name, $lang-name, 'i')]
                  return
                     string($i/@id)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:lang-name" as="xs:string*">
      <!-- Input: the code of a language -->
      <!-- Output: the name of the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <xsl:param name="lang-code" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$iso-639-3/tan:iso-639-3/tan:l[@id = $lang-code]/@name"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-code) gt 0)">
            <xsl:value-of
               select="
                  for $i in $iso-639-3/tan:iso-639-3/tan:l[matches(@id, $lang-code, 'i')]
                  return
                     string($i/@name)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:lang-catalog" as="document-node()*">
      <!-- Input: language codes -->
      <!-- Output: the catalogs for those languages -->
      <xsl:param name="lang-codes" as="xs:string*"/>
      <xsl:variable name="lang-codes-rev"
         select="
            if ((count($lang-codes) lt 1) or $lang-codes = '*') then
               '*'
            else
               $lang-codes"/>
      <xsl:for-each select="$lang-codes-rev">
         <xsl:variable name="this-lang-code" select="."/>
         <xsl:variable name="these-catalog-uris"
            select="
               if ($this-lang-code = '*') then
                  (for $i in $languages-supported
                  return
                     $lang-catalog-map($i))
               else
                  $lang-catalog-map($this-lang-code)"/>
         <xsl:if test="not(exists($these-catalog-uris))">
            <xsl:message select="'No catalogs defined for', $this-lang-code"/>
         </xsl:if>
         <xsl:for-each select="$these-catalog-uris">
            <xsl:variable name="this-uri" select="resolve-uri(., $extra-parameters-base-uri)"/>
            <xsl:choose>
               <xsl:when test="doc-available($this-uri)">
                  <xsl:sequence select="doc($this-uri)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:message select="'Language catalog not available at ', $this-uri"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   <xsl:variable name="languages-supported" select="map:keys($lang-catalog-map)"/>
   
   <!-- LANGUAGE-SPECIFIC -->
   
   <!-- Greek -->
   
   <xsl:variable name="grc-tokens-without-accents" select="doc('lang/grc-tokens-without-accents.xml')/*/*"/>
   
   <xsl:function name="tan:greek-graves-to-acutes" as="xs:string?">
      <!-- Input: text with Greek -->
      <!-- Output: the same, but with grave accents changed to acutes -->
      <xsl:param name="greek-to-change" as="xs:string?"/>
      <xsl:variable name="this-text-nfkd" select="normalize-unicode($greek-to-change, 'nfkd')"/>
      <xsl:variable name="this-text-fixed" select="replace($this-text-nfkd, '&#x300;', '&#x301;')"/>
      <xsl:sequence select="normalize-unicode($this-text-fixed)"/>
   </xsl:function>
   
   <!-- Latin -->
   
   <xsl:variable name="latin-batch-replacements-1" as="element()*">
      <!-- These batch replacements try to aggressively reduce classical, medieval Latin texts to a minimal idiosyncratic but 
         common orthographic system. This converts items to lowercase. -->
      
      <!-- ligatures -->
      <replace pattern="v" replacement="u" flags="i" message="Converting every u to v"/>
      <replace pattern="j" replacement="i" flags="i" message="Converting every j to i"/>
      <replace pattern="oe" replacement="e" flags="i" message="Simplifying ligature oe as e"/>
      <replace pattern="ae" replacement="e" flags="i" message="Simplifying ligature ae as e"/>
      <!-- splitting words -->
      <replace pattern="(^|\P{{L}})qu(ae?|e|is?|os?|ibus)nam($|\P{{L}})" replacement="$1qu$2 nam$3" flags="i" message="Splitting qua/quis etc. and nam"/>
      <replace pattern="(^|\P{{L}})siqui(d|dem|s)?($|\P{{L}})" replacement="$1si qui$2$3" flags="i" message="Splitting si and quid/quis/quidem"/>
      <replace pattern="(^|\P{{L}})(ac|et)si($|\P{{L}})" replacement="$1$2 si$3" flags="i" message="Splitting ac/et and si"/>
      <replace pattern="(^|\P{{L}})etenim($|\P{{L}})" replacement="$1et enim$2" flags="i" message="Splitting et and enim"/>
      <replace pattern="(^|\P{{L}})quamobrem($|\P{{L}})" replacement="$1quam ob rem$2" flags="i" message="Splitting quam, ob, and rem"/>
      <replace pattern="(^|\P{{L}})quo(circa|modo)($|\P{{L}})" replacement="$1quo $2$3" flags="i" message="Splitting quo and circa/modo"/>
      <replace pattern="(^|\P{{L}})verumetium($|\P{{L}})" replacement="$1verum etium$2" flags="i" message="Splitting verum and etiam"/>
      <!-- c to d -->
      <replace pattern="quicquid" replacement="quidquid" flags="i" message="Converting quicquid to quidquid"/>
      <!-- c to t -->
      <replace pattern="terci" replacement="terti" flags="i" message="Converting terci to terti"/>
      <replace pattern="pocius" replacement="potius" flags="i" message="Converting pocius as potius"/>
      <replace pattern="ici([aeiou])" replacement="iti$1" flags="i" message="Converting c in icia/e/i/o/u to t"/>
      <replace pattern="aci([aeiou])" replacement="ati$1" flags="i" message="Converting c in acia/e/i/o/u to t"/>
      <!-- ch to c -->
      <replace pattern="archan" replacement="arcan" flags="i" message="Converting archan to arcan"/>
      <replace pattern="michi" replacement="mihi" flags="i" message="Converting michi to mihi"/>
      <replace pattern="(^|\P{{L}})char" replacement="car" flags="i" message="Converting char- to car-"/>
      <!-- adding d -->
      <replace pattern="(^|\P{{L}})astan" replacement="$1adstan" flags="i" message="Converting astan- to adstan-"/>
      <!-- d to n -->
      <replace pattern="(^|\P{{L}})adn" replacement="$1ann" flags="i" message="Converting adn- to ann-"/>
      <!-- h added -->
      <replace pattern="(^|\P{{L}})osann?a" replacement="$1hosanna" flags="i" message="Adding h to Hosanna"/>
      <!-- h dropped -->
      <replace pattern="abraham" replacement="abraam" flags="i" message="Dropping h from abraham"/>
      <replace pattern="coher" replacement="coer" flags="i" message="Dropping h from coher"/>
      <replace pattern="(^|\P{{L}})hebdo" replacement="$1ebdo" flags="i" message="Dropping h from hebdo (e.g., Hebdomades)"/>
      <replace pattern="iohann" replacement="ioann" flags="i" message="Dropping h from iohann (e.g., Iohannes)"/>
      <replace pattern="ihes" replacement="ies" flags="i" message="Dropping h from ihes (e.g., Ihesus)"/>
      <replace pattern="israhel" replacement="israel" flags="i" message="Dropping h from israhel"/>
      <!-- i to e -->
      <replace pattern="(^|\P{{L}})beni" replacement="$1bene" flags="i" message="Converting beni- to bene-"/>
      <replace pattern="alitud" replacement="aletud" flags="i" message="Converting alitud to aletud"/>
      <replace pattern="dilect" replacement="delect" flags="i" message="Converting dilect to delect"/>
      <replace pattern="itati($|\P{{L}})" replacement="itate$1" flags="i" message="converting -itati to -itate"/>
      <!-- i to u -->
      <replace pattern="emoliment" replacement="emolument" flags="i" message="Converting emoliment to emolument"/>
      <!-- m to mm -->
      <replace pattern="(^|\P{{L}})mamon(a|e)($|\P{{L}})" replacement="$1mammon$2$3" flags="i" message="Standardizing loanword mammon"/>
      <!-- n to m -->
      <replace pattern="circun" replacement="circum" flags="i" message="Converting circun to circum"/>
      <replace pattern="duntax" replacement="dumtax" flags="i" message="Converting duntax to dumtax"/>
      <replace pattern="nque" replacement="mque" flags="i" message="Converting nque to mque"/>
      <replace pattern="ntamen" replacement="mtamen" flags="i" message="Converting ntamen to mtamen"/>
      <replace pattern="conp" replacement="comp" flags="i" message="Converting conp to comp"/>
      <!-- ph to f -->
      <replace pattern="(pro|ne)phan" replacement="$1fan" flags="i" message="Converting ph in nephan/prophan to f"/>
      <!-- s to z -->
      <replace pattern="baptisa" replacement="baptiza" flags="i" message="Converting baptisa to baptiza"/>
      <!-- th to ct, e.g. authoritatis -->
      <replace pattern="author" replacement="auctor" flags="i" message="Converting author to auctor"/>
      <!-- y to i -->
      <replace pattern="hydr" replacement="hidr" flags="i" message="Converting hydr (e.g. hydras) to hidr"/>
      <replace pattern="mosyn" replacement="mosin" flags="i" message="Converting mosyn (e.g. elemosynis) to mosin"/>
      <replace pattern="myst" replacement="mist" flags="i" message="Converting myst (e.g. mysticam) to mist"/>
      <replace pattern="presbyt" replacement="presbit" flags="i" message="Converting presbyt (e.g. presbyteri) to presbit"/>
      <replace pattern="synag" replacement="sinag" flags="i" message="Converting synag (e.g. synagoga) to sinag"/>
      <!-- doubled letters -->
      <replace pattern="eleemo" replacement="elemo" flags="i" message="Converting ee in eleemo to e"/>
      <replace pattern="iic([ei])" replacement="ic$1" flags="i" message="Converting ii in iice/i to i"/>
      <replace pattern="necce" replacement="nece" flags="i" message="Converting necce to nece"/>
      <replace pattern="toll" replacement="tol" flags="i" message="Converting toll to tol"/>
      <replace pattern="commod" replacement="comod" flags="i" message="Converting commod to comod"/>
      <replace pattern="penittus" replacement="penitus" flags="i" message="Converting penittus to penitus"/>
      <replace pattern="litter" replacement="liter" flags="i" message="Converting litter to liter"/>
      <replace pattern="quott" replacement="quot" flags="i" message="Converting quott to quot"/>
      <replace pattern="(^|\P{{L}})paruum($|\P{{L}})" replacement="$1parum$3" flags="i" message="Converting paruum to parum"/>
      <!-- proper nouns -->
      <replace pattern="(^|\P{{L}})chana($|\P{{L}})" replacement="$1cana$2" flags="i" message="Standardizing proper noun Cana"/>
      <replace pattern="(^|\P{{L}})h?i?ezechkele?" replacement="$1ezechiel" flags="i" message="Standardizing proper noun Ezechiel"/>
      <replace pattern="(^|\P{{L}})[hi]+eremia" replacement="$1ieremia" flags="i" message="Standardizing proper noun Ieremias"/>
      <replace pattern="(^|\P{{L}})[ih]+er[ou]s[ao]l[ye]m" replacement="$1ierosolym" flags="i" message="Standardizing proper noun Ierosolyma"/>
      <replace pattern="(^|\P{{L}})[yh]?esaia" replacement="$1isaia" flags="i" message="Standardizing proper noun Isaias"/>
      <replace pattern="(^|\P{{L}})mo[iy]?s(i|em|en)($|\P{{L}})" replacement="$1moys$2$3" flags="i" message="Standardizing proper noun Moysis (Moses)"/>
      <replace pattern="(^|\P{{L}})syon($|\P{{L}})" replacement="$1sion$3" flags="i" message="Standardizing proper noun Sion"/>
      <replace pattern="(^|\P{{L}})th?[iy]moth" replacement="$1timoth" flags="i" message="Standardizing proper noun Timothe"/>
   </xsl:variable>
   
   
   <!-- Syriac -->
   
   <xsl:function name="tan:syriac-marks-to-word-end" as="xs:string?">
      <!-- Input: a string -->
      <!-- Output: the string with Syriac marks placed at the end, in codepoint order -->
      <!-- This function was written to assist in comparing Syriac words that match. Which letter a 
         particular dot is placed should not matter, in most cases. -->
      <xsl:param name="input-syriac-text" as="xs:string?"/>
      <xsl:variable name="output-parts" as="xs:string*">
         <xsl:analyze-string select="$input-syriac-text" regex="[\p{{L}}\p{{M}}]+">
            <xsl:matching-substring>
               <xsl:variable name="these-marks" select="replace(., '\p{L}+', '')"/>
               <xsl:variable name="these-mark-codepoints-sorted" select="sort(string-to-codepoints($these-marks))"/>
               <xsl:variable name="these-letters" select="replace(., '\p{M}+', '')"/>
               <xsl:value-of select="$these-letters"/>
               <xsl:value-of select="codepoints-to-string($these-mark-codepoints-sorted)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:value-of select="string-join($output-parts)"/>
   </xsl:function>
   
   <xsl:variable name="syriac-batch-replacements-1" as="element()+">
      <!-- For best results, remove combining marks before applying these batch replacements -->
      <!-- marks -->
      <!--<replace pattern="([\p{{L}}\p{{M}}]+)(&#x307;)(\P{{L}}+)" replacement="$1$3$2" flags="i" message="Moving overdot mark (U+0307 COMBINING DOT ABOVE) to end of word"/>
      <replace pattern="(\p{{L}}+)(&#x308;)(\P{{L}}+)" replacement="$1$3$2" flags="i" message="Moving plural, seyame mark (U+0308 COMBINING DIAERESIS) to end of word"/>-->
      <!-- splitting words -->
      <replace pattern="(^[ܒܕܘܠ]?|\P{{L}}[ܒܕܘܠ]?)ܟܠܡܕܡ($|\P{{L}})" replacement="$1ܟܠ ܡܕܡ$2" flags="i" message="Splitting kl and mdm ('everything')"/>
      <!-- yodh removed -->
      <replace pattern="ܐܣܟܝܡ" replacement="ܐܣܟܡ" flags="i" message="Standardizing Syriac word root askm ('schema')"/>
      <!-- proper nouns -->
      <replace pattern="ܐܝܣܪܝܠ" replacement="ܐܝܣܪܐܝܠ" flags="i" message="Standardizing proper noun Israel"/>
      
   </xsl:variable>
   
   
</xsl:stylesheet>
