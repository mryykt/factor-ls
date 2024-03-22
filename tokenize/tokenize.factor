USING: kernel splitting lexer
sequences ;
IN: language-server.tokenize

: token ( tokens str -- new-tokens )
  suffix ;

: tokenize ( str -- tokens )
  "\n" split <lexer>
    [ { }
      [ ?scan-token dup ]
      [ token ] while ] with-lexer drop ;