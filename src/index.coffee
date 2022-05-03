import * as Val from "@dashkite/joy/value"
import { confidential } from "panda-confidential"
import URLTemplate from "es6-url-template"

failure = (code) -> new Error code

Confidential = confidential()

Base64 =
  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 4

JSON36 =
  encode: (value) ->
    Confidential.convert
      from: "utf8"
      to: "base36"
      JSON.stringify value
  
  decode: (value) ->
    JSON.parse Confidential.convert
      from: "base36"
      to: "utf8"
      value

canonicalize = ( authorization, nonce, secret ) ->
  Confidential.Message.from "utf8",
    JSON.stringify [ authorization, nonce, secret ]

mac = ( message ) ->
  Confidential.convert
    from: "bytes"
    to: "base64"
    ( Confidential.hash message ).hash[0..31]

_issue = ( authorization, secret, nonce ) ->
  rune = JSON36.encode [
    authorization
    mac canonicalize authorization, 
      nonce, 
      secret
  ]
  { rune, nonce }

issue = ( authorization, secret ) ->
  _issue authorization, secret, await Base64.nonce()

verify = ( rune, secret, nonce ) ->
  [ authorization, hash ] = JSON36.decode rune
  derived = _issue authorization, secret, nonce
  derived.rune == rune

discover = ({ origin }) ->
  response = await fetch origin, headers: accept: "application/json"
  response.json()

_getResource = ({ api, name }) -> api.resources[name]

getResource = ( context ) ->
  ( _getResource context ) ?
    throw failure "invalid resource", context

getTarget = ( context ) ->
  { bindings } = context
  template = getTemplate context
  expandTemplate template, bindings

expandTemplate = (template, parameters) ->
  (new URLTemplate template).expand parameters

getTemplate = ( context ) ->
  getResource context
    .template

getURL = ( context ) ->
  new URL (getTarget context), context.origin

match = ( request, { origin, grants, expires }) ->
  api = await discover { origin }
  for { resources, methods, bindings } in grants
    for name in resources
      try
        url = getURL { origin, api, name, bindings }
        if request.url == url.href
          if request.method in methods
            return true
      catch error
        console.error error
  false

_storage = {}
store = ({ rune, nonce }) ->
  [ { domain, grants } ] = JSON36.decode rune
  _storage[ domain ] ?= {}
  for grant in grants
    for resource in grant.resources
      for method in grant.methods
        { bindings } = grant
        _storage[ domain ][ resource ] ?= {}
        _storage[ domain ][ resource ][ method ] ?= { rune, nonce, bindings }
  null

lookup = ({ domain, resource, bindings, method }) ->
  if ( result = _storage[ domain ]?[ resource ]?[ method ] )?
    if Val.equal bindings, result.bindings
      result

has = ( query ) -> ( lookup query )?

export { issue, verify, match, JSON36, store, lookup, has }