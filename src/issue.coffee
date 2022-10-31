import { When, Confidential, JSON36 } from "./helpers"

canonicalize = ( authorization, nonce, secret ) ->
  Confidential.Message.from "utf8",
    JSON.stringify [ authorization, nonce, secret ]

mac = ( message ) ->
  Confidential.convert
    from: "bytes"
    to: "base64"
    ( Confidential.hash message ).hash[0..31]

make = ( authorization, secret, nonce ) ->
  rune = JSON36.encode [
    authorization
    mac canonicalize authorization, 
      nonce, 
      secret
  ]
  { rune, nonce }

issue = ({ authorization, secret }) ->
  make {
    authorization...
    expires: When.toISOString When.now().add authorization.expires
  }, secret, await JSON36.nonce()

export { issue, make }