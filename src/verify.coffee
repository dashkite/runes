import { make } from "./issue"
import { JSON64, When } from "./helpers"

verify = ({ rune, secret, nonce }) ->
  [ authorization, hash ] = JSON64.decode rune
  if authorization.expires >= When.toISOString When.now()
    derived = make authorization, secret, nonce
    derived.rune == rune
  else false

export { verify }