import { When, Confidential, encode, Nonce } from "./helpers"

canonicalize = ( authorization, nonce, secret ) ->
  Confidential.Message.from "utf8",
    JSON.stringify [ authorization, nonce, secret ]

mac = ( message ) ->
  Confidential.convert
    from: "bytes"
    to: "base64"
    ( Confidential.hash message ).hash[0..31]

make = ( authorization, secret, nonce ) ->
  rune = encode [
    authorization
    mac canonicalize authorization, 
      nonce, 
      secret
  ]
  { rune, nonce }

issue = ({ authorization, secret }) ->
  make {
    authorization...
    expires: When.timestamp authorization.expires
  }, secret, await Nonce.generate()

export { issue, make }