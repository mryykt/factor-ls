USING: kernel  namespaces continuations accessors vocabs vocabs.loader
io io.encodings io.encodings.utf8 io.encodings.binary io.encodings.string
json math math.parser formatting combinators
sequences assocs linked-assocs
language-server.tokenize ;
IN: language-server

TUPLE: source tokens vocab-name loaded-vocabs word-list ;

: <source> ( -- source )
  source new ;

! global variable
SYMBOLS: publish-diagnostics-capable diagnostics sources ;

: send ( obj -- )
  >json dup length "Content-Length: %d\r\n\r\n" printf
  write flush ;

: send-notification ( method params -- )
  [let :> params :> method
  <linked-hash>
    "jsonrpc" "2.0" set-of
    "method" method set-of
    "params" params set-of
  send ] ;

: send-response ( id result -- )
    [let :> result :> id
    <linked-hash>
      "jsonrpc" "2.0" set-of
      "id" id set-of
      "result" result set-of
    send ] ;

: send-log ( msg -- )
  [let :> msg
  "window/logMessage"
  <linked-hash>
    "type" 3 set-of
    "message" msg set-of
  send-notification ] ;

: send-publish-diagnostics ( uri diagnostics -- )
  [let :> diagnostics :> uri
  publish-diagnostics-capable get-global
  [
    <linked-hash>
    "jsonrpc" "2.0" set-of
    "method" "textDocument/publishDiagnostics" set-of
    "params"
      <linked-hash>
      "uri" uri set-of
      "diagnostics" diagnostics set-of
      set-of
    send ] when ] ;

: send-err ( id code msg -- )
  [let :> msg :> code :> id
  <linked-hash>
    "jsonrpc" "2.0" set-of
    "id" id set-of
    "code" code set-of
    "message" msg set-of
    send ] ;

: send-invalied-request ( -- )
  json-null -32600 "received an invalied request" send-err ;

: send-method-not-found ( id method -- )
  -32601 swap send-err ;

: initialize ( msg -- )
  [let :> msg
  <linked-hash>
  "jsonrpc" "2.0" set-of 
  "id" dup msg at set-of
  "result"
    <linked-hash>
    "capabilities"
      <linked-hash>
      "textDocumentSync" 1 set-of 
      "completionProvider" LH{ } set-of
    set-of
  set-of
  msg "params" of "capabilities" of "textDocument" of
    [ "publishDiagnostics" of [ t publish-diagnostics-capable set-global ] when ] when*
  send ] ;

: completion ( msg -- )
  [let :> msg
  msg "params" of "textDocument" of "uri" of
  sources get-global at word-list>> keys
  [ "label" <linked-hash> spin set-of ] map
  "result" <linked-hash> spin set-of
  "jsonrpc" "2.0" set-of
  "id" dup msg at set-of
  send ] ;

: handle-request ( msg method -- )
  {
    { "initialize" [ initialize ] }
    { "textDocument/completion" [ completion ] }
    [ swap "id" of swap send-method-not-found ]
  } case ;

: <range> ( start-line start-char end-line end-char -- range )
  [| sl sc el ec |
      <linked-hash>
      "start" <linked-hash> "line" sl set-of "character" sc set-of set-of
      "end" <linked-hash> "line" el set-of "character" ec set-of set-of ] call ;

: new-source ( uri src -- )
  [ tokenize <source> swap >>vocab-name swap >>loaded-vocabs swap >>tokens swap
  sources get-global set-at ]
  [ "tokenize error:%u" sprintf send-log 2drop ] recover ;

: changed-source ( uri src -- )
  [| uri src |
  src tokenize
  uri sources get-global at 
  swap >>vocab-name swap >>loaded-vocabs tokens<< ] [ "tokenize error:%u" sprintf send-log 2drop ] recover ;

: push-words ( words vocab-name assoc -- )
  [let :> assoc :> vocab-name
  [ name>> vocab-name swap assoc set-at ] each ] ;

: make-word-list ( vocabs vocab -- assoc )
  [let <linked-hash> :> word-list
  dup >vocab-link vocab-words swap word-list push-words
  [ dup >vocab-link vocab-words swap word-list push-words ] each
  word-list
  ] ;

: update-source ( uri vocabs vocab -- )
  dup reload
  make-word-list swap
  sources get-global at
  word-list<< ;

: handle-notification ( msg method -- )
  dup send-log
  {
    { "initialized" [ drop "initialized." send-log ] }
    { "textDocument/didOpen"
      [ [let :> msg
        msg "params" of "textDocument" of "uri" of dup
        msg "params" of "textDocument" of "text" of
        new-source
        diagnostics get-global
        send-publish-diagnostics ] ] }
    { "textDocument/didChange"
      [ [let :> msg
        msg "params" of "contentChanges" of length 0 = not
          [ msg "params" of "textDocument" of "uri" of dup
          msg "params" of "contentChanges" of dup
            length 1 - swap nth "text" of
          changed-source
          diagnostics get-global
          send-publish-diagnostics ] when ] ] }
    { "textDocument/didSave"
      [ [let :> msg
        msg "params" of "textDocument" of "uri" of dup
        sources get-global at
        dup loaded-vocabs>> swap vocab-name>>
        update-source ] ] }
    { "textDocument/didClose"
      [ [let :> msg
        msg "params" of "textDocument" of "uri" of
        { }
        send-publish-diagnostics ] ] }
    [ send-log drop ]
  } case ;

: read-msg ( -- obj )
  16 read drop ! read "Content-Length: "
  "\r" read-until drop string>number "\n" read-until 2drop ! read "nnn"
  "\n" read-until 2drop ! skip blank-line
  read utf8 decode json> ;

: dispatch ( -- ? )
  read-msg dup dup "id" swap key?
    [ "method" ?of
      [ handle-request ]
      [ 2drop ] if ] ! invalid message
    [ "method" ?of
      [ handle-notification ]
      [ 2drop send-invalied-request ] if ] if
  t ;

: ls ( -- )
  f publish-diagnostics-capable set-global
  { } diagnostics set-global
  <linked-hash> sources set-global
  binary decode-input
  [ [ dispatch ] loop ] [ "error: %u" sprintf send-log ] recover ;

MAIN: ls