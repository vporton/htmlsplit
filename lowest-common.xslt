<!-- Find lowest common ancestor of and XML nodes set.
     Code was borrowed from http://stackoverflow.com/q/8742002/856090 -->

<xsl:stylesheet version="2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:my="my:my">

  <xsl:function name="my:lca" as="node()?">
    <xsl:param name="pSet" as="node()*"/>

    <xsl:sequence select=
      "if(not($pSet))
        then ()
        else
          if(not($pSet[2]))
            then $pSet[1]
            else
            for $n1 in $pSet[1],
                $n2 in $pSet[last()]
              return my:lca2nodes($n1, $n2)
      "/>
  </xsl:function>

  <xsl:function name="my:lca2nodes" as="node()?">
    <xsl:param name="pN1" as="node()"/>
    <xsl:param name="pN2" as="node()"/>

    <xsl:variable name="n1" select=
      "($pN1 | $pN2)
                  [count(ancestor-or-self::node())
                  eq
                    min(($pN1 | $pN2)/count(ancestor-or-self::node()))
                  ]
                    [1]"/>

    <xsl:variable name="n2" select="($pN1 | $pN2) except $n1"/>

    <xsl:sequence select=
      "$n1/ancestor-or-self::node()
                [exists(. intersect $n2/ancestor-or-self::node())]
                    [1]"/>
  </xsl:function>

</xsl:stylesheet>