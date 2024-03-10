USING: kernel math math.parser io formatting json
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

: dispatch ( -- ? )
  16 read drop ! read "Content-Length: "
  "\r\n" read-until drop string>number ! read "nnn"
  "\r\n" read-until 2drop ! skip blank-line
  read json>
  dup "id" swap key?
    [ "method" ?of
      [ "request" send-log drop ]
      [ drop ] if ]
    [ "method" ?of
      [ "notification" send-log drop ]
      [ drop send-invalied-request ] if ] if
    t ;

: ls ( -- )
  [ dispatch ] loop ;

MAIN: ls