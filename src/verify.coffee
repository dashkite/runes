import { make } from "./issue"
import { decode, When } from "./helpers"

verify = ({ rune, secret, nonce }) ->
  [ authorization, hash ] = decode rune
  if authorization.expires >= When.toISOString When.now()
    derived = make authorization, secret, nonce
    derived.rune == rune
  else false

export { verify }