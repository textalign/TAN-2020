<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended numeric functions. -->

   <xsl:function name="tan:counts-to-lasts" xml:id="f-counts-to-lasts" as="xs:integer*" visibility="public">
      <!-- Input: sequence of numbers representing counts of items. 
         Output: sequence of numbers representing the last position of each item within the total count.
      E.g., (4, 12, 0, 7) - > (4, 16, 16, 23)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j])"/>
   </xsl:function>

   <xsl:function name="tan:lengths-to-positions" as="xs:integer*" visibility="public">
      <!-- Input: sequence of numbers representing legnths of items.  -->
      <!-- Output: sequence of numbers representing the first position of each input item, if the sequence concatenated.
      E.g., (4, 12, 0, 7) - > (1, 5, 17, 17)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j]) - $seq[$i] + 1"/>
   </xsl:function>

   <xsl:function name="tan:product" as="xs:double?" visibility="public">
      <!-- Input: a sequence of numbers -->
      <!-- Output: the product of those numbers -->
      <xsl:param name="numbers" as="item()*"/>
      <xsl:copy-of select="tan:product-loop($numbers[1], subsequence($numbers, 2))"/>
   </xsl:function>
   
   <xsl:function name="tan:product-loop" as="xs:double?" visibility="private">
      <xsl:param name="product-so-far" as="xs:double?"/>
      <xsl:param name="numbers-to-multiply" as="item()*"/>
      <xsl:choose>
         <xsl:when test="count($numbers-to-multiply) lt 1">
            <xsl:copy-of select="$product-so-far"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:product-loop(($product-so-far * xs:double($numbers-to-multiply[1])), subsequence($numbers-to-multiply, 2))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:number-sort" as="xs:double*" visibility="public">
      <!-- Input: any sequence of items -->
      <!-- Output: the same sequence, sorted with string numerals converted to numbers -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-norm" as="item()*" select="
            for $i in $numbers
            return
               if ($i castable as xs:double) then
                  number($i)
               else
                  $i"/>
      <xsl:for-each select="$numbers-norm">
         <xsl:sort/>
         <xsl:copy-of select="."/>
      </xsl:for-each>
   </xsl:function>



</xsl:stylesheet>
