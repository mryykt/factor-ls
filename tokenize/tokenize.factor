USING: kernel splitting namespaces lexer accessors
sequences ;
IN: language-server.tokenize

TUPLE: token line character text ;
: <token> ( line character str -- token )
  token new swap >>text swap >>character swap >>line ;

: add-token ( tokens line character str -- new-tokens )
  <token> suffix ;

: tokenize ( str -- tokens )
  split-lines <lexer>
    [ { }
      [ lexer get dup still-parsing-line? not [ dup next-line ] when dup line>> swap column>> ?scan-token dup ]
      [ add-token ] while ] with-lexer 3drop ;