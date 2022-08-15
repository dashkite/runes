import { JSON36 } from "./helpers"

# TODO in theory it's still possible to have two runes 
#      associated with the same identity/origin/resource/method tuple

store = ({ rune, nonce }) ->
  [ { identity, origin, grants } ] = JSON36.decode rune
  if (data = localStorage.getItem identity)?
    _identity = JSON.parse data
  else
    _identity = {}
  _identity[ origin ] ?= {}
  for grant in grants
    for resource in grant.resources
      for method in grant.methods
        { bindings } = grant
        _identity[ origin ][ resource ] ?= {}
        _identity[ origin ][ resource ][ method ] = { rune, nonce, bindings }
  localStorage.setItem identity, JSON.stringify _identity
  null

lookup = ({ identity, origin, resource, bindings, method }) ->
  if (data = localStorage.getItem identity)?
    _identity = JSON.parse data
    if ( result = _identity[ origin ]?[ resource ]?[ method ] )?
      result

has = ( query ) -> ( lookup query )?

export { store, lookup, has }