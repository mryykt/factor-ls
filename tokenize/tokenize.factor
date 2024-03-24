USING: kernel splitting namespaces lexer combinators accessors vocabs words io
sequences ;
IN: language-server.tokenize

TUPLE: token line character text ;
: <token> ( line character str -- token )
  token new swap >>text swap >>character swap >>line ;

SYMBOLS: current-vocab loaded-vocab ;

: next-token ( -- line character str )
  lexer get dup still-parsing-line? not [ dup next-line ] when dup line>> swap column>> scan-token ;

: add-vocab-names ( tokens -- tokens semicolon )
  [ next-token dup ";" = ]
  [ dup loaded-vocab get-global swap suffix loaded-vocab set-global <token> suffix ]
  until <token> ;

: add-token ( tokens line character str -- new-tokens )
  { { [ dup "IN:" = ] [ <token> suffix next-token dup current-vocab set-global <token> ] }
    { [ dup "USE:" = ] [ <token> suffix next-token dup loaded-vocab get-global swap suffix loaded-vocab set-global <token> ] }
    { [ dup "USING:" = ] [ <token> suffix add-vocab-names ] }
    [ <token> ]
  } cond
  suffix ;

: tokenize ( str -- tokens vocab-names vocab-name )
  f current-vocab set-global
  { } loaded-vocab set-global
  split-lines <lexer>
    [ { }
      [ lexer get dup still-parsing-line? not [ dup next-line ] when dup line>> swap column>> ?scan-token dup ]
      [ add-token ] while ] with-lexer 3drop
    loaded-vocab get-global
    current-vocab get-global ;