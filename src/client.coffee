import { JSON36 } from "./helpers"

store = ({ rune, nonce }) ->
  [ { identity, origin, grants, scope } ] = JSON36.decode rune
  if (data = window.localStorage.getItem identity)?
    _identity = JSON.parse data
  else
    _identity = {}
  _identity[ origin ] ?= {}
  for grant in grants
    for resource in grant.resources
      for method in grant.methods
        { bindings } = grant
        _identity[ origin ][ resource ] ?= {}
        _identity[ origin ][ resource ][ method ] ?= []
        _identity[ origin ][ resource ][ method ].push { rune, nonce, bindings, scope }
  window.localStorage.setItem identity, JSON.stringify _identity
  null

lookup = ({ identity, origin, resource, bindings, method }) ->
  if (data = window.localStorage.getItem identity)?
    _identity = JSON.parse data
    if ( results = _identity[ origin ]?[ resource ]?[ method ] )?
      for result in results
        if result.scope?
          if bindings[result.scope] == result.bindings[result.scope]
            return result
        else
          return result

has = ( query ) -> ( lookup query )?

export { store, lookup, has }