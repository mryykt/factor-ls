USING: accessors kernel combinators words help help.markup formatting math
sequences strings ;
IN: language-server.help

: words>md ( word -- str )
 name>> "`%s`" sprintf ;

: parameter>md ( help word: ( a -- b ) -- str )
  [let :> rec
    [ dup length 2 >=
      [ [ first rec call ] [ 1 tail [ rec call ] map "" join ] bi "- *%s* : %s" sprintf ]
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
    { [ dup \ $quotation = ] [ drop 1 tail [ "%u" sprintf ] map " " join "a `quotation` with stack effect `%s`" sprintf ] }
    { [ dup \ $snippet = ] [ drop 1 tail [ rec call ] map "" join "`%s`" sprintf ] }
    { [ dup \ $description = ] [ drop 1 tail [ rec call ] map "" join "### Description\n%s" sprintf ] }
    [ 2drop " " ]
  } cond ] ; inline

GENERIC: help>md-element ( help -- str )
M: string help>md-element ;
M: sequence help>md-element [ help>md-element ] seq>md ;
M: word help>md-element name>> dup a/an swap "%s `%s`" sprintf ;

: help>md ( seq -- str )
  [ help>md-element ] map "\n" join ;