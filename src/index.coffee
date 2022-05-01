import { confidential } from "panda-confidential"

Confidential = confidential()

Base64 =
  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 4

JSON64 =
  encode: (value) ->
    Confidential.convert
      from: "utf8"
      to: "base64"
      JSON.stringify value
  
  decode: (value) ->
    JSON.parse Confidential.convert
      from: "base64"
      to: "utf8"
      value

canonicalize = ( authorization, nonce, secret ) ->
  Confidential.Message.from "utf8",
    JSON.stringify [ authorization, nonce, secret ]

mac = ( message ) ->
  Confidential.convert
    from: "bytes"
    to: "base64"
    ( Confidential.hash message ).hash[0..31]

_issue = ( authorization, secret, nonce ) ->
  rune = JSON64.encode [
    authorization
    mac canonicalize authorization, 
      nonce, 
      secret
  ]
  { rune, nonce }

issue = ( authorization, secret ) ->
  _issue authorization, secret, await Base64.nonce()

verify = ( rune, secret, nonce ) ->
  [ authorization, hash ] = JSON64.decode rune
  derived = _issue authorization, secret, nonce
  derived.rune == rune

export { issue, verify, JSON64 }