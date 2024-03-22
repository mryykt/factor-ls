USING: kernel splitting namespaces lexer accessors
sequences ;
IN: language-server.tokenize

TUPLE: token line character text ;
: <token> ( line character str -- token )
  token new swap >>text swap >>character swap >>line ;

: add-token ( tokens line character str -- new-tokens )
  <token> suffix ;

: tokenize ( str -- tokens )
  "\n" split <lexer>
    [ { }
      [ lexer get dup line>> swap column>> ?scan-token dup ]
      [ add-token ] while ] with-lexer 3drop ;