USING: accessors kernel combinators words help help.markup formatting
sequences strings ;
IN: language-server.help

: words>md ( word -- str )
 name>> "`%s`" sprintf ;

: parameter>md ( help word: ( a -- b ) -- str )
  [let :> rec
    [ dup length 2 =
      [ first2 [ rec call ] bi@ "- *%s* : %s" sprintf ]
      [ drop "" ] if 
    ] map "\n" join ] ; inline

: $inputs>md ( help word: ( a -- b ) -- str )
  parameter>md
  "### Inputs\n%s" sprintf ; inline

: $outputs>md ( help word: ( a -- b ) -- str )
  parameter>md
  "### Outputs\n%s" sprintf ; inline

: $maybe>md ( help word: ( a -- b ) -- str )
  [let :> rec
    [ rec call "%s or `f`" sprintf ] map "\n" join
  ] ; inline

: seq>md ( seq word: ( a -- b ) -- str )
  [let :> rec
  dup first
  { { [ dup \ $inputs = ] [ drop 1 tail rec $inputs>md ] }
    { [ dup \ $outputs = ] [ drop 1 tail rec $outputs>md ] }
    { [ dup \ $maybe = ] [ drop 1 tail rec $maybe>md ] }
    [ 2drop " " ]
  } cond ] ; inline

GENERIC: help>md-element ( help -- str )
M: string help>md-element ;
M: sequence help>md-element [ help>md-element ] seq>md ;
M: word help>md-element name>> dup a/an swap "%s `%s`" sprintf ;

: help>md ( seq -- str )
  [ help>md-element ] map "\n" join ;