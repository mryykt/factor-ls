USING: accessors kernel combinators words help help.markup formatting
sequences strings ;
IN: language-server.help

: words>md ( word -- str )
 name>> "`%s`" sprintf ;

: $inputs>md ( help word: ( a -- b ) -- str )
  [let :> rec
    [ dup length 2 =
      [ first2 rec call "- %s: %s" sprintf ]
      [ drop "" ] if 
    ] map "\n" join
    "### Inputs\n%s" sprintf ] ; inline

: $outputs>md ( help word: ( a -- b ) -- str )
  [let :> rec
    [ dup length 2 =
      [ first2 rec call "- %s: %s" sprintf ]
      [ drop "" ] if 
    ] map "\n" join
    "### Outputs\n%s" sprintf ] ; inline

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

: help>md-element ( help -- str )
  { { [ dup sequence? ] [ [ help>md-element ] seq>md ] }
    { [ dup word? ] [ name>> "`%s`" sprintf ] }
    { [ dup string? ] [ ] }
    [ drop "" ]
  } cond ;

: help>md ( seq -- str )
  [ help>md-element ] map "\n" join ;