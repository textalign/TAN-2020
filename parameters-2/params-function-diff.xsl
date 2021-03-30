<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
   exclude-result-prefixes="#all" version="3.0">
   <!-- Global parameters pertaining to TAN applications making use of tan:diff() and tan:collate(). 
      This stylesheet is meant to be imported (not included) by other stylesheets, so that the
      parameter values can be changed. -->
   
   <!-- DIFF ALGORITHM SETTINGS -->
   
   <!-- How many vertical stops should be used in tan:diff()? Large numbers do not penalize performance. Short numbers will
      exhaust loop tolerance on long texts and turn the operation over to the longest common substring program. When this
      parameter is set to 80, and the other parameters are given their default values, the final sample size in the vertical 
      stop will be 9.094947E-13. That's a samples size of one character from a string of length one trillion. -->
   <xsl:param name="tan:diff-vertical-stop-count" as="xs:integer" select="100"/>
   
   <!-- A sequence of doubles, descending from 1.0 to no lower than zero, specifing what portion of the length of the text should 
        be checked, i.e., the sequence of percentages to be checked at each outer loop pass. -->
   <xsl:param name="tan:diff-vertical-stops" select="
         for $i in (1 to $tan:diff-vertical-stop-count)
         return
            math:pow($tan:diff-sample-size-attenuation-base, ($tan:diff-sample-size-attenuation-rate * $i))"/>
   
   <!-- How steeply should sample sizes attenuate? The value serves to change the exponent by which sample sizes diminish.
      With the default, 0.5 (and assuming an attenuation base of 0.5), the sample sizes proceed 71%, 50%, 35%, ... 
      Lowering it to 0.25 results
      in samples sizes of 84%, 71%, 59%, 50%, ... This parameter's value will have no effect if $tan:diff-vertical-stops has been
      overridden.
   -->
   <xsl:param name="tan:diff-sample-size-attenuation-rate" as="xs:decimal" select="0.5"/>
   
   <!-- Where is the basis or center of the sample size series? Expected is a decimal between 1.0 and 0.0, with 
      0.5 being the default. Lowering from 0.5 progressively slows down the diminishment of the sample sizes, and puts more
      emphasis on large fragment checks. Greater
      than 0.5 accelerates them, and puts more emphasis on smaller sample fragments. This parameter's value will 
      have no effect if $tan:diff-vertical-stops has been
      overridden.
   -->
   <xsl:param name="tan:diff-sample-size-attenuation-base" as="xs:decimal" select="0.5"/>
   
   
   <!-- What is the maximum number of horizontal passes to be applied in a given diff? -->
   <xsl:param name="tan:diff-maximum-number-of-horizontal-passes" as="xs:integer" select="50"/>
   
   <!-- The number of samples will increase from 1 to the maximum. How quickly should it rise? Expected is a positive
      number above 0, with 0.5 being the default, to reach the maximum relatively quickly. This number has 
      exponential power over the complement of the sample size. The higher the number the greater the number
      of samples at the beginning of the vertical stops. This factor does not greatly affect the end of the
      vertical stops. With the default series of sample sizes, 71%, 50%, 35%, ... and a maximum of 50 samples,
      the number of samples proceeds 5, 13, 21, 29, 34, ... if the parameter is set to 0.5. If it is 1, it would be 
      15, 26, 33, 38, 42, ... The higher number plus a smaller maximum number of horizontal passes would help 
      cases where it is known that the two texts are rather alike.
   -->
   <xsl:param name="tan:diff-horizontal-pass-frequency-rate" as="xs:decimal" select="0.5"/>
   
   <!-- At what point is the shortest string so long that it would be better pre-process via tokenization? 
      This preprocessing is best when applied to large strings that are rather alike. -->
   <xsl:param name="tan:diff-preprocess-via-tokenization-trigger-point" as="xs:integer" select="300000"/>
   
   <!-- What is the size of the smallest string permitted before preprocessing the input via segmentation? 
      If both strings are larger than this value, they will be pushed to tan:giant-diff() and cut into segments. -->
   <xsl:param name="tan:diff-preprocess-via-segmentation-trigger-point" as="xs:integer" select="3000000"/>
   
   <!-- When segmenting enormous strings to be fed through giant diff, what is the maximum size allowed for any
      input string segment? Be certain to keep this below the segmentation trigger point. -->
   <xsl:param name="tan:diff-max-size-of-giant-string-segments" as="xs:integer"
      select="xs:integer($tan:diff-preprocess-via-segmentation-trigger-point * 0.98)"/>
   <!-- What is the minimum number of segments into which a giant string should be chopped when processing a tan:giant-diff()? 
      The lower the number, the better the accuracy. A higher number might yield faster results. -->
   <xsl:param name="tan:diff-min-count-giant-string-segments" as="xs:integer" select="2"/>
   
   
</xsl:stylesheet>
