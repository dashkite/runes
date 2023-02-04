import { make } from "./issue"
import { decode, When } from "./helpers"

verify = ({ rune, secret, nonce }) ->
  try
    [ authorization, hash ] = decode rune
    if authorization.expires >= When.toISOString When.now()
      derived = make authorization, secret, nonce
      derived.rune == rune
    else false
  catch
    false

export { verify }