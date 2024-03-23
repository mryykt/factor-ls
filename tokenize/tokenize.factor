USING: kernel splitting namespaces lexer combinators accessors vocabs words io
sequences ;
IN: language-server.tokenize

TUPLE: token line character text ;
: <token> ( line character str -- token )
  token new swap >>text swap >>character swap >>line ;

SYMBOL: current-vocab

: next-token ( -- line character str )
  lexer get dup still-parsing-line? not [ dup next-line ] when dup line>> swap column>> ?scan-token ;

: add-token ( tokens line character str -- new-tokens )
  { { [ dup "IN:" = ] [ <token> suffix next-token dup current-vocab set-global <token> ] }
    [ <token> ]

  } cond
  suffix ;

: tokenize ( str -- tokens vocab-name )
  f current-vocab set-global
  split-lines <lexer>
    [ { }
      [ next-token dup ]
      [ add-token ] while ] with-lexer 3drop
    current-vocab get-global ;