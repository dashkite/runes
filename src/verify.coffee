import { make } from "./issue"
import { JSON36, When } from "./helpers"

verify = ({ rune, secret, nonce }) ->
  [ authorization, hash ] = JSON36.decode rune
  if authorization.expires >= When.toISOString When.now()
    derived = make authorization, secret, nonce
    derived.rune == rune
  else false

export { verify }