USING: kernel math math.parser io formatting json combinators
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

: handle-request ( msg method -- )
  {
    { "initialize"
      [ [let :> msg
        <linked-hash>
        "jsonrpc" "2.0" set-of 
        "id" dup msg at set-of
        "result"
          <linked-hash>
          "capabilities"
            LH{  { "textDocumentSync" 1 } }
          set-of
        set-of
        send ] ] }
    [ drop dup "id" swap at "method" swap at send-method-not-found ]
  } case ;

: handle-notification ( msg method -- )
  {
    { "initialized" [ drop "initialized." send-log ] }
    { "textDocument/didOpen"
      [ [let :> msg
        ! msg "params" of "textDocument" of "uri" of :> uri
        msg "params" of "textDocument" of "text" of send-log ] ] }
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
  [ dispatch ] loop ;

MAIN: ls