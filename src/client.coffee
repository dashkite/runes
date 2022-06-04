import { JSON36 } from "./helpers"

# TODO in theory it's still possible to have two runes 
#      associated with the same identity/origin/resource/method tuple

# TODO use idb or localstorage
_storage = {}
store = ({ rune, nonce }) ->
  [ { identity, origin, grants } ] = JSON36.decode rune
  _storage[ identity ] ?= {}
  _storage[ identity ][ origin ] ?= {}
  for grant in grants
    for resource in grant.resources
      for method in grant.methods
        { bindings } = grant
        _storage[ identity ][ origin ][ resource ] ?= {}
        _storage[ identity ][ origin ][ resource ][ method ] = { rune, nonce, bindings }
  null

lookup = ({ identity, origin, resource, bindings, method }) ->
  if ( result = _storage[ identity ]?[ origin ]?[ resource ]?[ method ] )?
    result

has = ( query ) -> ( lookup query )?

export { store, lookup, has }