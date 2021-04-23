<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to the TAN application for remodeling a text against a class 1 file. -->

   <!-- This is the public face of the application. The application proper can be found by
      following any links in an <xsl:include> or <xsl:import>. You are invited to alter any of 
      the parameters in this file as you like, to customize the application. You may want to 
      make copies of this file, to apply to specific situations.
   -->

   <!-- DESCRIPTION -->

   <!-- Primary (catalyzing) input: any XML file -->
   <!-- Secondary input: a TAN-T(EI) that exemplifies a model reference system that 
        the input should imitate -->
   <!-- Primary output: the original catalyzing input, but with the text infused into the 
        <div> structure of the model. The text allocated to the new <div> structure proportionate 
        to the text length in the model. -->
   <!-- Secondary output: none -->

   <!-- This application is intended to help users restructure a text, particularly for cases where
      you have a good TAN model, and you want to introduce subsequent versions (translations, paraphrases, 
      other versions). The output will likely be imperfect, because rarely are two versions synchronized. 
      The output will require further editing and refinement. It is a good idea to adopt a progressive
      strategy. See suggestions below. -->
   
   <!-- Nota bene:
      * If the catalyzing input file is not a class-1 file, but just an XML file, it will be read
      for its string value, the output will be a copy of the model with the string proportionately
      allocated to its body components.
      * If you remodel a set of sibling leaf divs but exclude certain intervening leaf divs from 
      being remodeled, the entire remodel will be placed at the location of the first leaf div only. 
      That is, that area of the remodel will be consolidated, and the text will no longer
      reflect the original order. 
      * Because this application produces TAN output, metadata will be supplied to the output, along
      with a change entry, crediting/blaming the application.
      * Comparison is made with the model on the basis of resolved, not expanded, class 1 files, and
      any matches involving @n or @n-built references will be on the basis of resolved numerals. 
   -->
   
   <!-- Strategies for use:
    
    Method: gentle increments
    1. Run plain text against the model.
    2. Edit the output, focusing only on getting the top-level divisions correct.
    3. Change the parameter $preserve-matching-ref-structures-up-to-what-level to 1.
    4. Run the edited input against the model again. Your top-level divisions should remain intact.
    5. Edit the output, focusing only on getting the 2nd-level divisions correct.
    6. Repeat ##3-5 through the rest of the hierarchy.
    Use this method in tandem with the TAN editing tools in Oxygen, where you can easily push and pull
    entire words, clauses, and sentences from one leaf div to another. When you are editing (##2, 5),
    place the model in a parallel window.
    
    Method: complete the square (not yet supported)
    Sometimes you have a model text in version A that is in two different reference systems (A1 and A2). 
    You now want to work on version B, and set up TAN-T(EI) versions in both reference systems (B1 and B2).
    1. Apply the gentle increments method to version B on ref system 1.
    2. Make sure that A1 and A2 point to each other through mutual <redivision>s.
    3. Add to version B1 a <model> that points to A1.
    4. Run B1 against A2 with this application. It will check to see if there is an intermediate version
    (A1) against which it can more precisely calibrate the portions of B1.
    5. Edit B2 along the lines discussed under gentle increments.
    The method is called complete the square, because #4 assumes this:
    A1   A2
    B1  [  ]
    The version A1 becomes instrumental in making its catacorner counterpart more accurate. This method 
    was first introduced in the stable 2020 application, but as of March 2021, after two major revisions, 
    the complete the square method has not been implemented. 
    
    Working with non-XML input
    You might have text from some non-XML source that you want to feed into this method. If you can get
    down to the plain text, put it into any XML file, and run it through this application, changing the 
    parameter $model-uri-relative-to-catalyzing-input to specify exactly where the model is. You'll get 
    the model with the text infused. It will need a lot of metadata editing, but at least you'll have a 
    good start on getting the body structured. -->
   

   <!-- PARAMETERS -->
   
   <!-- STEP 1: THE MODEL -->
   
   <!-- Where is the model relative to the catalyzing input? Default is the @href for the first <model> within the input file. -->
   <xsl:param name="model-uri-relative-to-catalyzing-input" as="xs:string?"
      select="tan:first-loc-available(/*/tan:head/tan:model[1])"/>
   
   <!-- What top-level divs should be excluded (kept intact) from the input? Expected: a regular expression matching @n. 
      If blank, this has no effect. -->
   <xsl:param name="exclude-from-model-top-level-divs-with-attr-n-values-regex" as="xs:string?" select="''"/>
   
   <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type. If blank, 
      this has no effect. -->
   <xsl:param name="exclude-from-model-divs-with-attr-type-values-regex" as="xs:string?" select="''"/>
   
   
   <!-- STEP 2: THE INPUT -->

   <!-- Many of the following parameters assume input of a class-1 file. -->

   <!-- What top-level divs should be excluded (preserved intact) from the remodeling? Expected: a 
      regular expression matching @n. If blank, this has no effect. -->
   <xsl:param name="exclude-from-input-top-level-divs-with-attr-n-values-regex" as="xs:string?" select="'epilogue|^2$'"/>
   
   <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type. 
      If blank, this has no effect. -->
   <xsl:param name="exclude-from-input-divs-with-attr-type-values-regex" as="xs:string?" select="'test'"/>
   
   <!-- At what level should remodeling begin? By setting this value to 1 or greater, you will 
      preserve existing <div> structures, and remodeling will occur starting only at the next tier
      deeper. At the first acceptable level, remodeling will be performed in concert with <div>s
      in the model whose ref value matches the current input <div>s calculated ref value (where a
      <div>s ref value are all the permutations of combining the values of @ns in itself and all its
      ancestors). If there is no corresponding match in the model, that div will be deep copied, and
      rendered exempt from the remodelling. This feature is extremely helpful for incremental modeling,
      e.g., where a class 1 file preserves only the topmost hierarchy of its model, and needs to be 
      subdivide further, or where a class 1 file needs to be recalibrated but only at a certain depth. -->
   <xsl:param name="preserve-matching-ref-structures-up-to-what-level" as="xs:integer?" select="0"/>
   
   <!-- Does the model have a material (scriptum-oriented) reference system or a logical one? -->
   <xsl:param name="model-has-scriptum-oriented-reference-system" as="xs:boolean" select="true()"/>
   
   <!-- What regular expression should be used to decide where breaks are allowed if the model has 
      a scriptum-based structure? -->
   <xsl:param name="break-text-at-material-divs-regex" as="xs:string"
      select="$tan:word-end-regex"/>
   
   <!-- What regular expression should be used to decide where breaks are allowed if the model has a 
      logical (non-scriptum) reference system? $tan:clause-end-regex is good for texts with ample punctuation; 
      if a language makes use of word spaces, $tan:word-end-regex will prevent individual words from being
      divided.
   -->
   <xsl:param name="break-text-at-logical-divs-regex" as="xs:string" select="$tan:clause-end-regex"
   />
   
   <!-- If chopping up segments of text, should parenthetical clauses be preserved intact? -->
   <xsl:param name="do-not-chop-parenthetical-clauses" as="xs:boolean" select="false()"/>
   
   
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/remodel%20text%20core.xsl"/>

</xsl:stylesheet>
