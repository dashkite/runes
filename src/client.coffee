import { JSON36 } from "./helpers"

store = ({ rune, nonce }) ->
  [ { identity, domain, grants, scope } ] = JSON36.decode rune
  if (data = localStorage.getItem identity)?
    _identity = JSON.parse data
  else
    _identity = {}
  _identity[ domain ] ?= {}
  for grant in grants
    for resource in grant.resources
      for method in grant.methods
        { bindings } = grant
        _identity[ domain ][ resource ] ?= {}
        _identity[ domain ][ resource ][ method ] ?= []
        _identity[ domain ][ resource ][ method ].push { rune, nonce, bindings, scope }
  localStorage.setItem identity, JSON.stringify _identity
  null

lookup = ({ identity, domain, resource, bindings, method }) ->
  if (data = localStorage.getItem identity)?
    _identity = JSON.parse data
    if ( results = _identity[ domain ]?[ resource ]?[ method ] )?
      for result in results
        if result.scope?
          if bindings[result.scope] == result.bindings[result.scope]
            return result
        else
          return result

has = ( query ) -> ( lookup query )?

export { store, lookup, has }