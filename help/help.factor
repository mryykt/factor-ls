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

: seq>md ( seq word: ( a -- b ) -- str )
  [let :> rec
  dup first
  { { [ dup \ $inputs = ] [ drop 1 tail rec $inputs>md ] }
    [ 2drop " " ]
  } cond ] ; inline

: help>md-element ( help -- str )
  { { [ dup sequence? ] [ [ help>md-element ] seq>md ] }
    { [ dup word? ] [ name>> "`%s`" sprintf ] }
    { [ dup string? ] [ ] }
    [ drop "" ]
  } cond ;

: help>md ( seq -- str )
  [ help>md-element ] map concat ;