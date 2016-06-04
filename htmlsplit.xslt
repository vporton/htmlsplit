<xsl:stylesheet
  xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
  xmlns:xs = "http://www.w3.org/2001/XMLSchema"
  xmlns:fn = "http://www.w3.org/2005/xpath-functions"
  xmlns = "http://www.w3.org/1999/xhtml"
  xmlns:split = "http://portonvictor.org/ns/split"
  xmlns:html = "http://www.w3.org/1999/xhtml"
  xmlns:my = "my:my"
  xmlns:data = "http://portonvictor.org/ns/misc"
  version = "2.0"
  exclude-result-prefixes = "xs fn data my html split"
  xpath-default-namespace = "">

  <xsl:import href="lowest-common.xslt"/>

  <!-- Preliminary declarations -->

  <xsl:output
    method = "xhtml"
    byte-order-mark = "no"
    encoding = "utf-8"
    indent = "no"
    media-type = "text/html"
    omit-xml-declaration = "yes"
    version = "1.1" />

  <!-- Parameters -->

  <!-- TODO: Option to remove comments -->
  <xsl:param name="output-directory" select="'.'"/>
  <xsl:param name="config-filename"/>

  <!-- Load configuration -->

  <xsl:variable name="system-settings" select="document('settings.xml')"/>
  <xsl:variable name="user-settings" select="if($config-filename) then document($config-filename, $input-document) else ()"/>

  <xsl:variable name="toc-filename" select="($user-settings/*/toc-filename, $system-settings/*/toc-filename)[1]/text()"/>
  <xsl:variable name="toc-content" select="($user-settings/*/toc-content, $system-settings/*/toc-content)[1]/node()"/>
  <xsl:variable name="chapter-filename" select="($user-settings/*/chapter-filename, $system-settings/*/chapter-filename)[1]/node()"/>
  <xsl:variable name="skip-chapters" select="xs:integer(($user-settings/*/skip-chapters, $system-settings/*/skip-chapters)[1]/text())"/>
  <xsl:variable name="skip-chapter-header" select="($user-settings/*/skip-chapter-header, $system-settings/*/skip-chapter-header)[1]/text()"/>

  <!-- By default if the document has more than one <h1> use 'h1', otherwise 'h2'. -->
  <xsl:variable name="chapter-tag-configured" select="($user-settings/chapter-tag, $system-settings/chapter-tag)[1]/text()"/>
  <xsl:variable name="chapter-tag">
    <xsl:choose>
      <xsl:when test="$chapter-tag-configured">
        <xsl:value-of select="$chapter-tag-configured"/>
      </xsl:when>
      <xsl:when test="($input-document//html:h1)[2]">
        <xsl:value-of select="'h1'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'h2'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Start processing the input document -->

  <xsl:variable name="input-document" select="/"/>
  <xsl:variable name="doc-title" select="/html:html/html:head/html:title/text()"/>
  <xsl:variable name="body-attrs" select="/html:html/html:body/@*"/>
  <xsl:variable name="head" select="/html:html/html:head/node()[fn:not(self::html:title)]"/>

  <!-- Parse settings.xml and user's settings -->

<!--  First define particular-option(), then
      my:extract-option((particular-option($user-settings), particular-option($system-settings))) -->
  <xsl:function name="my:extract-option">
    <xsl:param name="option-containers"/> <!-- sequence of nodes containing options, the first item takes priority -->
    <xsl:param name="option-name"/>
    <xsl:if test="$option-containers">
      <xsl:variable name="value" select="$option-containers[1]/*[local-name() eq $option-name]"/>
      <xsl:choose>
        <xsl:when test="$value">
          <xsl:copy-of copy-namespaces="no" select="$value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="my:extract-option(fn:subsequence($option-containers, 2), $option-name)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:function>

  <xsl:function name="my:toc-settings-files1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/toc-page/files, $config-file/settings/generic-page/files"/>
  </xsl:function>

  <xsl:function name="my:toc-settings-macros1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/toc-page/macros, $config-file/settings/generic-page/macros"/>
  </xsl:function>

  <xsl:function name="my:toc-settings-header1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/toc-page/header, $config-file/settings/generic-page/header"/>
  </xsl:function>

  <xsl:function name="my:toc-settings-strip-style1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/toc-page/strip-style, $config-file/settings/generic-page/strip-style"/>
  </xsl:function>

  <xsl:function name="my:toc-settings-ignore-head1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/toc-page/ignore-head, $config-file/settings/generic-page/ignore-head"/>
  </xsl:function>

  <xsl:variable name="toc-settings-files" select="my:toc-settings-files1($user-settings), my:toc-settings-files1($system-settings)"/>
  <xsl:variable name="toc-settings-macros" select="my:toc-settings-macros1($user-settings), my:toc-settings-macros1($system-settings)"/>
  <xsl:variable name="toc-settings-header" select="(my:toc-settings-header1($user-settings), my:toc-settings-header1($system-settings))[1]/node()"/>
  <xsl:variable name="toc-settings-strip-style" select="(my:toc-settings-strip-style1($user-settings), my:toc-settings-strip-style1($system-settings))[1]/text()"/>
  <xsl:variable name="toc-settings-ignore-head" select="(my:toc-settings-ignore-head1($user-settings), my:toc-settings-ignore-head1($system-settings))[1]/text()"/>

  <xsl:function name="my:chapter-settings-files1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/chapter-page/files, $config-file/settings/generic-page/files"/>
  </xsl:function>

  <xsl:function name="my:chapter-settings-macros1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/chapter-page/macros, $config-file/settings/generic-page/macros"/>
  </xsl:function>

  <xsl:function name="my:chapter-settings-header1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/chapter-page/header, $config-file/settings/generic-page/header"/>
  </xsl:function>

  <xsl:function name="my:chapter-settings-strip-style1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/chapter-page/strip-style, $config-file/settings/generic-page/strip-style"/>
  </xsl:function>

  <xsl:function name="my:chapter-settings-ignore-head1">
    <xsl:param name="config-file"/>
    <xsl:copy-of copy-namespaces="no" select="$config-file/settings/chapter-page/ignore-head, $config-file/settings/generic-page/ignore-head"/>
  </xsl:function>

  <xsl:variable name="chapter-settings-files" select="my:chapter-settings-files1($user-settings), my:chapter-settings-files1($system-settings)"/>
  <xsl:variable name="chapter-settings-macros" select="my:chapter-settings-macros1($user-settings), my:chapter-settings-macros1($system-settings)"/>
  <xsl:variable name="chapter-settings-header" select="(my:chapter-settings-header1($user-settings), my:chapter-settings-header1($system-settings))[1]/node()"/>
  <xsl:variable name="chapter-settings-strip-style" select="(my:chapter-settings-strip-style1($user-settings), my:chapter-settings-strip-style1($system-settings))[1]/text()"/>
  <xsl:variable name="chapter-settings-ignore-head" select="(my:chapter-settings-ignore-head1($user-settings), my:chapter-settings-ignore-head1($system-settings))[1]/text()"/>

  <!-- Load and pre-process the input file -->

  <!-- The very first stage of processing: split the document into fragments, which will be named chapterN.html. -->
  <xsl:template name="split">
    <xsl:variable name="container" select="my:lca(.//html:*[local-name() eq $chapter-tag])"/> <!-- In test-div.xml example it is <div class="container"> -->
    <xsl:variable name="start" select="$container/node()[descendant-or-self::html:*[local-name() eq $chapter-tag]][1]"/> <!-- the first chapter header in the document -->
    <xsl:for-each-group select="$start|$start/following-sibling::node()"
                        group-starting-with="*[descendant-or-self::html:*[local-name() eq $chapter-tag]]">
      <xsl:if test="position() gt $skip-chapters">
        <data:doc>
          <xsl:attribute name="filename">
            <xsl:apply-templates mode="chapter-filename" select="$chapter-filename">
              <xsl:with-param name="number" select="position()" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:attribute>
          <xsl:copy-of copy-namespaces="no" select="current-group()"/>
        </data:doc>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template mode="chapter-filename" match="number">
    <xsl:param name="number" tunnel="yes"/>
    <xsl:value-of select="$number"/>
  </xsl:template>

  <xsl:template mode="chapter-filename" match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template mode="adjust-links" match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="adjust-links" select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- TODO: Should we preserve relative links which point to an anchor inside the same chapter? -->
  <xsl:template mode="adjust-links" match="html:a">
    <xsl:param name="chapters" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="adjust-links" select="@*"/>
      <xsl:variable name="uri" select="replace(@href, '^\s+|\s+$', '')"/> <!-- https://www.w3.org/TR/2014/REC-html5-20141028/infrastructure.html#valid-non-empty-url-potentially-surrounded-by-spaces -->
      <xsl:if test="fn:substring($uri,1,1) eq '#'">
        <xsl:variable name="id" select="fn:substring($uri,2)"/>
        <xsl:variable name="link-target-chapter" select="$chapters/data:doc[.//*[@id eq $id]][1]"/>
        <xsl:attribute name="href" select="concat($link-target-chapter/@filename, $uri)"/>
      </xsl:if>
      <xsl:apply-templates mode="adjust-links" select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="preprocessed-input">
    <xsl:variable name="stage1">
      <xsl:call-template name="split"/>
    </xsl:variable>
    <xsl:apply-templates mode="adjust-links" select="$stage1">
      <xsl:with-param name="chapters" select="$stage1" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:template name="output">
    <xsl:call-template name="output-toc"/>
    <xsl:for-each select="$preprocessed-input/data:doc">
      <xsl:variable name="filename" select="fn:string(@filename)"/>
      <xsl:call-template name="output-chapter">
        <xsl:with-param name="filename" select="$filename" tunnel="yes"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template mode="wrapper" match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="wrapper" select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="wrapper" match="html:head">
    <xsl:param name="settings-ignore-head" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="wrapper" select="@*"/>
      <xsl:if test="$settings-ignore-head ne 'yes'">
        <xsl:apply-templates mode="head" select="$head"/>
      </xsl:if>
      <xsl:apply-templates mode="wrapper" select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="head" match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="head" select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="head" match="html:style">
    <xsl:param name="settings-strip-style" tunnel="yes"/>
    <xsl:if test="$settings-strip-style ne 'yes'">
      <xsl:copy copy-namespaces="no">
        <xsl:apply-templates mode="wrapper" select="@*|node()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="wrapper" match="html:body">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="wrapper" select="@*"/>
      <xsl:copy-of copy-namespaces="no" select="$body-attrs"/>
      <xsl:apply-templates mode="wrapper" select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:content">
    <xsl:param name="filetype" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$filetype eq 'toc'">
        <xsl:apply-templates mode="wrapper" select="$toc-content"/>
      </xsl:when>
      <xsl:when test="$filetype eq 'chapter'">
        <xsl:call-template name="output-chapter-inner"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:toc">
     <xsl:call-template name="output-toc-inner"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:macro">
    <xsl:param name="settings-macros" tunnel="yes"/>
    <xsl:apply-templates mode="wrapper" select="my:extract-option($settings-macros, @name)/node()"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:insert-file">
    <xsl:param name="settings-files" tunnel="yes"/>
    <xsl:apply-templates mode="wrapper" select="document(my:extract-option($settings-files, @alias)/node(), $input-document)"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:doc-title">
    <xsl:value-of select="$doc-title"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:chapter-title">
    <xsl:param name="chapter-title" tunnel="yes"/>
    <xsl:apply-templates mode="wrapper" select="$chapter-title"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:plain">
    <xsl:variable name="content">
      <xsl:apply-templates mode="wrapper" select="node()"/>
    </xsl:variable>
    <xsl:value-of select="$content"/>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:next">
    <xsl:param name="next-uri" tunnel="yes"/>
    <xsl:if test="$next-uri">
      <a href="{$next-uri}">
        <xsl:apply-templates select="@*|node()"/>
      </a>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:prev">
    <xsl:param name="prev-uri" tunnel="yes"/>
    <xsl:if test="$prev-uri">
      <a href="{$prev-uri}">
        <xsl:apply-templates select="@*|node()"/>
      </a>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:toc-ref">
    <a href="{$toc-filename}">
      <xsl:apply-templates select="@*|node()"/>
    </a>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:if">
    <xsl:variable name="condition">
      <xsl:apply-templates mode="condition" select="@*"/>
    </xsl:variable>
    <xsl:if test="$condition ne ''">
      <xsl:apply-templates mode="wrapper" select="node()"/>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="wrapper" match="split:unless">
    <xsl:variable name="condition">
      <xsl:apply-templates mode="condition" select="@*"/>
    </xsl:variable>
    <xsl:if test="$condition eq ''">
      <xsl:apply-templates mode="wrapper" select="node()"/>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="condition" match="@test[. eq 'toc']">
    <xsl:param name="is-toc" tunnel="yes"/>
    <xsl:copy-of copy-namespaces="no" select="$is-toc"/>
  </xsl:template>

  <xsl:template mode="condition" match="@test[. eq 'has-next']">
    <xsl:param name="next-uri" tunnel="yes"/>
    <xsl:copy-of copy-namespaces="no" select="if($next-uri) then '1' else ''"/>
  </xsl:template>

  <xsl:template mode="condition" match="@test[. eq 'has-prev']">
    <xsl:param name="prev-uri" tunnel="yes"/>
    <xsl:copy-of copy-namespaces="no" select="if($prev-uri) then '1' else ''"/>
  </xsl:template>

  <!-- ToC output -->

  <xsl:template name="output-toc">
    <xsl:result-document href="{$output-directory}/{$toc-filename}">
      <xsl:apply-templates mode="wrapper" select="document(my:extract-option($toc-settings-files, 'wrapper'), $input-document)">
        <xsl:with-param name="filetype" select="'toc'" tunnel="yes"/>
        <xsl:with-param name="next-uri" select="$preprocessed-input/*[1]/@filename" tunnel="yes"/>
        <xsl:with-param name="is-toc" select="1" tunnel="yes"/>
        <xsl:with-param name="settings-files" select="$toc-settings-files" tunnel="yes"/>
        <xsl:with-param name="settings-macros" select="$toc-settings-macros" tunnel="yes"/>
        <xsl:with-param name="settings-header" select="$toc-settings-header" tunnel="yes"/>
        <xsl:with-param name="settings-strip-style" select="$toc-settings-strip-style" tunnel="yes"/>
        <xsl:with-param name="settings-ignore-head" select="$toc-settings-ignore-head" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="output-toc-inner">
    <xsl:param name="filename" tunnel="yes"/>
    <xsl:for-each select="$preprocessed-input/*">
      <xsl:call-template name="toc-item">
        <xsl:with-param name="link" select="@filename"/>
        <xsl:with-param name="text" select=".//html:*[local-name() eq $chapter-tag]/node()"/>
        <xsl:with-param name="is-current" select="$filename eq @filename"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Overrides may use $filetype tunnel parameters to output different for the main ToC and a ToC embedded in a chapter. -->
  <xsl:template name="toc-item">
    <xsl:param name="link"/>
    <xsl:param name="text"/>
    <xsl:param name="is-current"/>
    <li>
      <a href="{$link}">
        <xsl:apply-templates mode="hyperlink-content" select="$text"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template mode="hyperlink-content" match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="hyperlink-content" select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="hyperlink-content" match="html:a"> <!-- No hyperlinks inside hyperlinks -->
    <xsl:apply-templates mode="hyperlink-content" select="node()"/>
  </xsl:template>

  <!-- Output a chapter -->

  <xsl:template name="output-chapter">
    <xsl:param name="filename" tunnel="yes"/>
    <xsl:result-document href="{$output-directory}/{$filename}">
      <xsl:variable name="chapter" select="node()"/>
      <xsl:variable name="chapter-title" select=".//html:*[local-name() eq $chapter-tag]/node()"/>
      <xsl:variable name="chapter-attrs" select=".//html:*[local-name() eq $chapter-tag]/@*"/>
      <xsl:apply-templates mode="wrapper" select="document(my:extract-option($chapter-settings-files, 'wrapper'), $input-document)">
        <xsl:with-param name="filetype" select="'chapter'" tunnel="yes"/>
        <xsl:with-param name="next-uri" select="following-sibling::*[1]/@filename" tunnel="yes"/>
        <xsl:with-param name="prev-uri" select="(preceding-sibling::*[1]/@filename, $toc-filename)[1]" tunnel="yes"/>
        <xsl:with-param name="is-toc" select="''" tunnel="yes"/>
        <xsl:with-param name="settings-files" select="$chapter-settings-files" tunnel="yes"/>
        <xsl:with-param name="settings-macros" select="$chapter-settings-macros" tunnel="yes"/>
        <xsl:with-param name="settings-header" select="$chapter-settings-header" tunnel="yes"/>
        <xsl:with-param name="settings-strip-style" select="$chapter-settings-strip-style" tunnel="yes"/>
        <xsl:with-param name="settings-ignore-head" select="$chapter-settings-ignore-head" tunnel="yes"/>
        <xsl:with-param name="chapter" select="$chapter" tunnel="yes"/>
        <xsl:with-param name="chapter-attrs" select="$chapter-attrs" tunnel="yes"/>
        <xsl:with-param name="chapter-title" select="$chapter-title" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>

  <xsl:template name="output-chapter-inner">
    <xsl:param name="chapter" tunnel="yes"/>
    <xsl:if test="$skip-chapter-header ne 'yes'">
      <xsl:call-template name="output-chapter-header">
        <xsl:with-param name="text" select="$chapter[1]"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:call-template name="output-chapter-text">
      <xsl:with-param name="text" select="$chapter[position() gt 1]"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-chapter-header">
    <xsl:param name="text"/>
    <xsl:apply-templates mode="chapter" select="$text"/>
  </xsl:template>

  <xsl:template name="output-chapter-text">
    <xsl:param name="text"/>
    <xsl:apply-templates mode="chapter" select="$text"/>
  </xsl:template>

  <xsl:template mode="chapter" match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="chapter" select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="chapter" match="html:*[local-name() eq $chapter-tag]">
    <xsl:param name="settings-header" tunnel="yes"/>
    <xsl:param name="chapter-attrs" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:copy-of copy-namespaces="no" select="$chapter-attrs"/>
      <xsl:apply-templates mode="wrapper" select="$settings-header"/>
    </xsl:copy>
  </xsl:template>

  <!-- The main entry point of our program -->

  <xsl:template match="/">
    <xsl:call-template name="output"/>
  </xsl:template>

</xsl:stylesheet>