USING: kernel io namespaces
json math math.parser formatting combinators
sequences assocs linked-assocs ;
IN: language-server

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

! global variable
SYMBOLS: publish-diagnostics-capable ;

: initialize ( msg -- )
  [let :> msg
  <linked-hash>
  "jsonrpc" "2.0" set-of 
  "id" dup msg at set-of
  "result"
    <linked-hash>
    "capabilities"
      LH{  { "textDocumentSync" 1 } }
    set-of
  set-of
  msg "params" of "capabilities" of "textDocument" of
    [ "publishDiagnostics" of [ t publish-diagnostics-capable set-global ] when ] when*
  send ] ;

: handle-request ( msg method -- )
  {
    { "initialize" [ initialize ] }
    [ swap "id" of swap send-method-not-found ]
  } case ;

: handle-notification ( msg method -- )
  {
    { "initialized" [ drop "initialized." send-log ] }
    { "textDocument/didOpen"
      [ [let :> msg
        ! msg "params" of "textDocument" of "uri" of :> uri
        msg "params" of "textDocument" of "text" of send-log ] ] }
    { "textDocument/didChange"
      [ [let :> msg
        msg "params" of "contentChanges" of length 0 = not
          [
            ! msg "params" of "textDocument" of "uri" of :> uri
          msg "params" of "contentChanges" of dup
            length 1 - swap nth "text" of send-log ] when ] ] }
    [ send-log drop ]
  } case ;

: read-msg ( -- obj )
  16 read drop ! read "Content-Length: "
  "\r\n" read-until drop string>number 2 + ! read "nnn"
  "\r\n" read-until 2drop ! skip blank-line
  read json> ;

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
  [ dispatch ] loop ;

MAIN: ls