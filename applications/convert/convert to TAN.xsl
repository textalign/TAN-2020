<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="incl/convert%20to%20TAN.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to the TAN application for converting a file to TAN. -->

   <!-- This is the public face of the application. The application proper can be found by
      following any links in an <xsl:include> or <xsl:import>. You are invited to alter any of 
      the parameters in this file as you like, to customize the application. You may want to 
      make copies of this file, to apply to specific situations.
   -->

   <!-- DESCRIPTION -->

   <!-- Primary (catalyzing) input: any XML file, ideally the TAN file that should be used
         as the target template into which the source file should be converted. -->
   <!-- Secondary input: a non-TAN file in plain text, XML, or Word format (docx), as 
         explained below -->
   <!-- Primary output: the TAN file with its contents replaced by a parsed analysis of the
         source. -->
   <!-- Secondary output: none -->

   <!-- This application is intended to help users convert a text to TAN-T, TAN-TEI, or TAN-A.
      This is a difficult task, mainly because the source text could be either plain text, 
      an XML file, or a Word document. If a Word document, the formatting *might* mean something,
      or it might not. Users tend to be inconsistent and incomplete in such formatting, and
      Word frequently breaks up adjacent text formatted the same, because it is preserving a
      record of editing history. The text itself is a challenge. We assume that there are in
      the text various numerals or words that signal reference numbers. A source text might have 
      multiple concurrent reference systems, and one must be picked, and the appropriate patterns 
      fed to the algorithm, to build the textual hierarchy correctly. This application has been
      designed for a select set of test cases. Your particular needs will no doubt vary, and the
      best way to approach this application is by customizing it, which will require some study
      of the underlying code.-->
   
   <!-- Some assumptions:
      * If the catalyzing input file is not a TAN file, then there will be a fallback, generic
      TAN file used, as determined by the parameters below.
      * If the catalyzing input file is TAN-T, that means the output will be as well, and only the 
      structured but plain text will be returned.
      * If the catalyzing input file is TAN-TEI, the TAN-TEI output will be structured text, with 
      select internal markup.
      * If the catalyzing input is TAN-A, then output will consist of annotations on the text. This
      option is supported only for Word files, whose comments are interpreted as TAN-A claims. 
   -->
   
   <!-- Nota bene:
      * Many input files will be full of internal inconsistency and error. Do not take results at
      face value. Scrutinize the output. If you see errors in the input, you can either fix the 
      input or customize this application to make those changes during processing. The latter is
      definitely to be preferred if the source text is a live, working document that you have 
      little control over, and there is even the slightest chance it might be revised, and need
      to be processed again.
      * This application works well with a TAN file that points to the source file in question. As
      that source file gets updated, the TAN file can be re-processed through this application, to
      refresh the results.
   -->
   
   

   <!-- PARAMETERS -->
   
   <!-- SOURCE INPUT -->
   
   <!-- Where is the source input file? Any relative path will be resolved against this stylesheet. 
      Resolved URIs would be unaffected, which you may wish to supply for this parameter, e.g., 
      "file:/c:/myfile.txt", or work with an @href that is in the catalyzing file. In many cases, 
      a class 1 file that is based upon live work being conducted in another file will ideally point to
      the source. Some suggestions:
         /*/tan:head/tan:source/tan:location/@href 
         /*/tan:head/tan:predecessor[1]/tan:location/@href 
      If the source input consists of multiple files, then the path can include glob-like wildcard
      characters, ? and *, to match certain patterns. Multiple files will be ordered alphabetically 
      by filename.
   -->
   <xsl:param name="relative-path-to-source-input" as="xs:string?"
      select="resolve-uri(
      (/*/tan:head/tan:predecessor/tan:location/@href, 
      /*/tan:head/tan:source/tan:location/@href)[1], 
      $tan:doc-uri)"/>

   <!-- TEMPLATE -->
   
   <!-- If the catalyzing input is not a TAN file, where is the TAN file that should be used as
      a template? Any relative path will be resolved against this stylesheet. If this value is empty, 
      or a TAN file cannot be found, a generic TAN-T file will be used. -->
   <xsl:param name="relative-path-to-fallback-TAN-template" as="xs:string?"
      select="$tan:default-tan-t-template-uri-resolved"/>


   <!-- ADJUSTING AND INTERPRETING THE INPUT -->
   
   <!-- What initial adjustments, if any, should be made to the text? Expected is a sequence of elements.
      The name of the elements is immaterial, but each one must have @pattern and @replacement. They may
      have @flags and @message. These attributes take the values one is supposed to provide to the XSLT
      function fn:replace(). That is, @pattern must be a regular expression, and @replacement must be a
      corresponding replacement, using capture groups as needed. @flags must be zero or more of the letters
      ixqms corresponding to case insensitive, ignore space, no special characters, multi-line mode, dot-all
      mode. For more see https://www.w3.org/TR/xpath-functions-31/#flags.
         These elements are processed by tan:batch-replace(). See documentation in the TAN library about 
      that function.
   -->
   <xsl:param name="initial-adjustments" as="element()*">
      <!-- Replacements for Evagrius docx -->
      <!--<replace pattern="(Chapter )(\d+)(\s+)\2\.\s*" replacement="$1$2$3" flags="i"
         message="Removing repeated chapter number $2."/>
      <replace pattern="\n(S[13]|Severus.+):\s*.+" replacement="" message="Removing entry for $1"/>
      <replace pattern="(\n)S2:\s*" replacement="$1"/>-->
   </xsl:param>
   
   <!-- If the input is in Word docx, should any deletions be ignored? -->
   <xsl:param name="ignore-docx-deletions" as="xs:boolean" select="true()"/>
   
   <!-- If the input is in Word docx, should any insertions be ignored? -->
   <xsl:param name="ignore-docx-insertions" as="xs:boolean" select="false()"/>
   
   <!-- What parts of the text signal divisions? This parameter takes a series of <marker> elements, each one
      containing one or more <where> elements and one or more <div> elements. 
         The <where> element is used to identify spans of text in the source input. It must contain a @pattern,
      a @format, or both. @pattern is a regular expression matching text. @format applies only to docx input,
      and accepts a handful of keywords identifying one or more formats that the text must be rendered in. If 
      the input is not a docx file, any <where> with a @format will be ignored.
         The <div> specifies the class 1 <div> element that should begin here. It must take @n and @type (which
      are required for the output TAN file) as well as @level, an integer that specifies how deep in the 
      hierarchy the <div> should be. Both @n and @type are interpreted like @replacement in the parameter above.
      That is, you can use $1 to capture the first parenthesized subexpression in a given <where>'s @pattern.
      You can use $0 to the entire captured string. For more on this concept, see examples below and the 
      discussion of $replacement at https://www.w3.org/TR/xpath-functions-31/#func-replace.
         These elements are also processed by tan:batch-replace(), in sequential order. Every span of text 
      that matches a <where> is replaced by the <div> anchors. After all markers are processed, the hierarchy
      will be constructed with tan:sequence-to-tree(), which rebuilds the hierarchy.
         All node insertions will be space-normalized.
   -->
   <xsl:param name="main-text-to-markup" as="element()*">
      <!--<markup>
         <where pattern="Preface pr" format="Heading1"/>
         <div level="1" type="preface" n="pr"/>
      </markup>
      <markup>
         <where pattern="Section (\d+)" format="Heading2"/>
         <div level="2" type="section" n="$1"/>
      </markup>
      <markup>
         <!-\- This looks for, e.g., "Pref 1" and converts it to a div marking a section within the preface. -\->
         <where pattern="pref\s*(\d+)" format="Heading2" flags="i"/>
         <div level="1" type="preface" n="pr"/>
         <div level="2" type="section" n="$1"/>
      </markup>
      <markup>
         <where pattern="century ([iv]+)" format="Heading1" flags="i"/>
         <div level="1" type="century" n="$1"/>
      </markup>
      <markup>
         <!-\- Note, this particular rule takes priority over the next one, which also
         looks for "chapter" -\->
         <where pattern="chapter (\d+)" format="Heading2" flags="i"/>
         <div level="2" type="chapter" n="$1"/>
      </markup>
      <markup>
         <!-\- This looks for, e.g., "Chapter 1" and converts it to a top-level div for a chapter. -\->
         <where pattern="chapter (\d+)" flags="i"/>
         <div level="1" type="chapter" n="$1"/>
      </markup>
      <markup>
         <!-\- This looks for, e.g., "head-1" and converts it to a top-level div for a head, and adapts the @n
            as "head_1". (This is for a text where such heads intermingle with numbered chapters, so the raw
            number should not be used. -\->
         <where pattern="(head)\D?(\d+)" format="Heading2" flags="i"/>
         <where pattern="(head) head_(\d+)" format="Heading1" flags="i"/>
         <div level="1" type="head" n="$1_$2"/>
      </markup>
      <markup>
         <!-\- Note, this particular rule takes priority over the next one, which also
         looks for "epilogue" -\->
         <where pattern="epilogue ep(\d?)" format="Heading1" flags="i"/>
         <div level="1" type="epilogue" n="ep$1"/>
      </markup>
      <markup>
         <where pattern="epilogue ep(\d?)" format="Heading2" flags="i"/>
         <div level="2" type="epilogue" n="ep$1"/>
      </markup>
      <markup>
         <!-\- This looks for "Epilogue" and marks it as belonging to the epilogue. -\->
         <where pattern="Epilogue\s*(ep)?" flags="i"/>
         <div level="1" type="epilogue" n="ep"/>
      </markup>
      <markup>
         <where pattern="para (\d+)" format="Heading2" flags="i"/>
         <div level="2" type="para" n="$1"/>
      </markup>-->
      
      <!-- markups for the CLIO collection -->
      <markup>
         <!-- First, mark the homily number, using dot-all mode and a reluctant match -->
         <where pattern="(\n|^)(Explanatio|Iohannis|Homilia [IVXL]|Omelia [IVXL]|Commentarius).+?(\d+)\.(\d+)\.(\d+)" 
            flags="s"/>
         <div level="1" type="hom" n="$3"/>
         <div level="2" type="title" n="title"/>
         <ab level="3"/>$0
      </markup>
      <markup>
         <where pattern="\[?Omelia.+[\)\]]" exclude-format="bold"/>
         <where pattern="\[Homilia.+\]"/>
         <div level="2" type="title" n="loc">
            <ab>$0</ab>
         </div>
      </markup>
      <markup>
         <!-- If it is centered and in square brackets, treat it as a manuscript
            title, but not if it is merely indicating the homily number. -->
         <where pattern="\[.+\]" format="center" exclude-pattern="(\[Omeli|Heiligenkreuz|\[Homilia)"/>
         <!-- If it is bold, treat it as an original title, unless it has the word
            "Explanatio", etc.,  which signals the initial title, already handled. -->
         <where format="bold" exclude-pattern="Explanatio|(Homi|Ome)lia [IVXL]|Commentarius|^\s+$"/>
         <div level="2" type="title" n="orig_title">
            <ab>$0</ab>
         </div>
      </markup>
      <markup>
         <where format="italic"/>
         <quote>$0</quote>
      </markup>
      <markup>
         <where pattern="(\d+)\.(\d+)\.(\d+)" exclude-format="center"/>
         <!-- In this particular pattern, the empty anchors represent the hierarchy
            that should be constructed. The text that follows will be wrapped by the 
            last element. -->
         <div level="1" type="hom" n="$1"/>
         <div level="2" type="sec" n="$2"/>
         <div level="3" type="sub" n="$3"/>
         <ab level="4"/>
      </markup>
   </xsl:param>
   
   
   <!-- How do you wish to handle orphan text? Orphan text is any text that must be placed 
      before the first <div> marker of a given level. The following options are supported:
      1 - delete orphan text
      2 - wrap orphan text in a <div type="section" n="orphan">
      3 - push orphan text into the first leaf <div> (default)
   -->
   <xsl:param name="orphan-text-option" as="xs:integer" select="1"/>
   
   
   <!-- Do any comments in an input Word document represent special markup? If so, provide 
      elements, similar to $main-text-to-markup, specifying how to manage the markup. It is 
      assumed that all elements represent TEI tags.
         Note: the <where> elements apply to the content of comments, not to the main text. 
      Each docx comment necessarily spans at least one character of the main text. The 
      comment can be converted to markup, to be placed either before or after the text 
      between the two anchors, or to wrap the text between the two anchors. The placeholder 
      element <maintext> specifies exactly where the text between the anchors should be placed 
      relative to the new markup.
         One complication with comments is that they might overlap, either with each other 
      or with the hierarchy that was just constructed via the process behind 
      $main-text-to-markup.
         The following rules must be observed:
         - The parameter consists of a sequence of <markup> elements. Each one has one or
         more <where> children, followed by any nodes.
         - A <markup> may have an attribute @cuts (default value false). If true, then if
         the starting anchor or ending anchor fall within an element (one that the other anchor
         does not fall within), then that element may be in two, with part of it falling outside
         the markup and part of it inside. If false (default), then that markup will be ignored
         because it would result in overlapping markup.
         - Each <markup> must include one and only one <maintext/> descendent, after the 
         <where> children. This specifies exactly where the text between the anchors will 
         be situated, and it allows you to situate it where you like.
         - If main text to which a comment is anchored has been deleted from an earlier process, 
         then the markup will not be inserted or applied.
         - Comments will be processed in document order. If any comment has anchors that overlaps 
         with a previous comment will be rejected.
         - No checks will be made on whether the resultant TEI fragment is valid or not. Validate
         the results to see what is wrong.
         - The markup will always be applied to the text nodes in a leaf element. That is just
         the nature of a comment: it annotates text. If you want to build TEI elements at a more 
         rootward level, use $main-text-to-markup.
         - The attribute @level is immaterial, because the markup will be applied at the
         level of the hierarchy where the text match occurs.
         - <markup> elements will be processed in order. Remember, though, a <markup> element
         merely fetches zero or more comments, and provides instructions on what to do with it.
         So a <markup> that matches a comment will prevent subsequent <markup> elements from
         acting on that comment. In general, put the most specific rules at the top. 
         - If a <maintext> is the first or last item in the sequence, then the markup will be
         treated as slicing the tree, and no overlap issues should arise.
   -->
   <xsl:param name="comments-to-markup" as="element()*">
      <!-- CLIO: Burgundio -->
      <markup>
         <where pattern="(Paris|Harley) (fol)\.\s*([0-9/rvab]+); (Paris|Harley) (fol)\.\s*([0-9/rvab]+)"/>
         <!-- Get all complex MS refs -->
         <milestone edRef="$1" unit="$2" n="$3"/>
         <milestone edRef="$4" unit="$5" n="$6" rend="$0"/>
         <maintext/>
      </markup>
      <markup>
         <where pattern="(Paris|Harley) (fol)\.\s*([0-9/rvab]+)"/>
         <!-- Get single complex MS refs -->
         <milestone edRef="$1" unit="$2" n="$3" rend="$0"/>
         <maintext/>
      </markup>
      <!-- CLIO: Griffolini -->
      <!-- milestones -->
      <!-- I added ? after : because sometimes the editor forgot it -->
      <markup>
         <where pattern="\[(1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+)\]"/>
         <milestone edRef="#W$1" unit="$2" n="$3" rend="$0"/>
         <maintext/>
      </markup>
      <markup>
         <where pattern="\[(1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); ?(1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+)\]"/>
         <milestone edRef="#W$1" unit="$2" n="$3"/>
         <milestone edRef="#W$4" unit="$5" n="$6" rend="$0"/>
         <maintext/>
      </markup>
      <markup>
         <where pattern="\[(1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); (1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); (1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+)\]"/>
         <milestone edRef="#W$1" unit="$2" n="$3"/>
         <milestone edRef="#W$4" unit="$5" n="$6"/>
         <milestone edRef="#W$7" unit="$8" n="$9" rend="$0"/>
         <maintext/>
      </markup>
      <markup>
         <where pattern="\[(1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); (1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); (1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+); (1462|1470|1486|1530|1556|1603|1728|1862):? (fol|p|col)\.\s*([0-9/rvab]+)\]"/>
         <milestone edRef="#W$1" unit="$2" n="$3"/>
         <milestone edRef="#W$4" unit="$5" n="$6"/>
         <milestone edRef="#W$7" unit="$8" n="$9"/>
         <milestone edRef="#W$10" unit="$11" n="$12" rend="$0"/>
         <maintext/>
      </markup>
      
      <!-- VARIANT READINGS -->
      
      <!-- variant readings, specific exceptions -->
      
      <markup cuts="true">
         <!-- for complex comments combining a 2-siglum variant reading with a 
            one-siglum milestone, e.g., Griffolini 39.2.22 -->
         <where pattern="((1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.+))(\((1462|1470|1486|1530|1556|1603|1728|1862):\s*(fol|p|col)\.\s*([0-9/rvab]+)\))"/>
         <milestone edRef="#W$7" unit="$8" n="$9" rend="$6"/>
         <app rend="$1">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$2 #W$3">$5</rdg>
         </app>
      </markup>
      <markup cuts="true">
         <!-- for 2 witnesses followed by 1 witness -->
         <where exclude-pattern="(fol|p|col)\.\s*([0-9/rvab]+)" pattern="(1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*);\s+(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1 #W$2">$4</rdg>
            <rdg wit="#W$5">$7</rdg>
         </app>
      </markup>
      <markup cuts="true">
         <!-- for 1 witness followed by 2 witnesses -->
         <where exclude-pattern="(fol|p|col)\.\s*([0-9/rvab]+)" pattern="(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*);\s+(1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1">$3</rdg>
            <rdg wit="#W$4 #W$5">$7</rdg>
         </app>
      </markup>
      <markup cuts="true">
         <!-- for 1 witnesses followed by 1 witness -->
         <where exclude-pattern="(fol|p|col)\.\s*([0-9/rvab]+)" pattern="(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*);\s+(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1">$3</rdg>
            <rdg wit="#W$4">$6</rdg>
         </app>
      </markup>
      
      <markup cuts="true">
         <!-- These patterns complain about unexpected complex comments. -->
         <where pattern="(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.+)\(.*\)" message="unexpected complex comment; parentheses not anticipated: $0"/>
         <where pattern="(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.+);.*\d" exclude-pattern="[\[\]]" message="unexpected complex comment; semicolon not anticipated: $0"/>
         <unexpected/>
         <maintext/>
      </markup>
      
      <!-- variant readings, generally -->
      
      <markup cuts="true">
         <!-- for 3 witnesses -->
         <where pattern="(1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1 #W$2 #W$3">$5</rdg>
         </app>
      </markup>
      <markup cuts="true">
         <!-- for 2 witnesses -->
         <where pattern="(1462|1470|1486|1530|1556|1603|1728|1862)/(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1 #W$2">$4</rdg>
         </app>
      </markup>
      <markup cuts="true">
         <!-- for 1 witness; sometimes the colon is dropped -->
         <where pattern="(1462|1470|1486|1530|1556|1603|1728|1862):?\s+(om\.)?(.*)"/>
         <app rend="$0">
            <lem>
               <maintext/>
            </lem>
            <rdg wit="#W$1">$3</rdg>
         </app>
      </markup>
      <!-- All CLIO versions, default -->
      <markup cuts="true">
         <where pattern="(fol)\.\s*([0-9/rvab]+)"/>
         <!-- Get MS refs without a siglum, and assume it belongs to Paris -->
         <milestone edRef="Paris" unit="$1" n="$2" rend="$0"/>
         <maintext/>
      </markup>
   </xsl:param>
   
   
   
   <!-- Do you wish to be notified of any comments that are not addressed by 
      $comments-to-markup? This has effect only if there are instructions to
      look for comments.
   -->
   <xsl:param name="report-ignored-comments" as="xs:boolean" select="true()"/>
   
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/convert%20to%20TAN%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
   
</xsl:stylesheet>
