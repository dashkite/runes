import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Val from "@dashkite/joy/value"
import * as Type from "@dashkite/joy/type"
import { expand } from "@dashkite/polaris"
import URITemplate from "uri-template.js"
import { Confidential, JSON36 } from "./helpers"
 
failure = (code) -> new Error code

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

issue = ({ authorization, secret }) ->
  date = new Date()
  expires = timestamp: null
  if authorization.expires.days?
    date.setDate date.getDate() + authorization.expires.days
    expires.timestamp = date.toISOString()
  else if authorization.expires.hours?
    date.setHours date.getHours() + authorization.expires.hours
    expires.timestamp = date.toISOString()
  else if authorization.expires.minutes?
    date.setMinutes date.getMinutes() + authorization.expires.minutes
    expires.timestamp = date.toISOString()
  else if authorization.expires.seconds?
    date.setSeconds date.getSeconds() + authorization.expires.seconds
    expires.timestamp = date.toISOString()

  authorization.expires = expires.timestamp
  _issue authorization, secret, await JSON36.nonce()

verify = ({ rune, secret, nonce }) ->
  [ authorization, hash ] = JSON36.decode rune
  date = new Date()
  if authorization.expires < date.toISOString()
    console.log "Rune Expired"
    return false
  derived = _issue authorization, secret, nonce
  derived.rune == rune

# discover = ({ fetch, origin }) ->
#   await fetch 
#     resource: { origin, name: "description" }
#     method: "get"
#     headers: accept: "application/json"

command = ( object ) ->
  [ name ] = Object.keys object
  { name, bindings: object[ name ] }

isCommand = ( object ) -> object?.name && object?.bindings

Resolvers =

  request: ( context, request ) ->
    { fetch } = context
    { resource } = request
    request.method ?= "get"
    resource.origin ?= context.authorization.origin
    console.log "Resolver Resource", resource
    console.log "Resolver Request", request
    response = await fetch request if ( request = await Grant.match { context..., request })?
    #TODO We should check the content-type?
    response.content

resolve = generic name: "enchant[resolve]"

generic resolve, Type.isObject, Type.isString, ( context, template ) ->
  expand template, context.data

generic resolve, Type.isObject, Type.isObject, ( context, action ) ->
  resolve context, command action

generic resolve, Type.isObject, isCommand, ( context, { name, bindings } ) ->
  Resolvers[ name ] context, bindings

# Request =
#   origin: ( request ) ->
#     request._url ?= new URL request.url
#     request._url.origin

#   target: ( request ) ->
#     url = ( request._url ?= new URL request.url )
#     url.pathname + url.search

# Resource =
#   find: do ( cache = {}) ->
#     ( context ) ->
#       { fetch, request } = context
#       origin = Request.origin request
#       target = Request.target request
#       api = ( cache[ origin ] ?= await discover { fetch, origin } )
#       for name, resource of api.resources
#         bindings = URITemplate.extract resource.template, target
#         if ( target == URITemplate.expand resource.template, bindings )
#           return { origin, name, bindings }
#       null

match = ( context ) ->
  { fetch, request, authorization } = context
  # resource = await Resource.find context
  { resource } = request
  if resource? && ( resource.origin == authorization.origin )
    Grant.match {
      context...
      request
      data: {} 
    }
  
mask = ( keys, object ) ->
  result = {}
  for key in keys
    result[ key ] = object[ key ]
  result

Bindings =

  resolve: ( context, bindings ) ->
    result = {}
    if bindings?
      for key, expression of bindings
        result[ key ] = await resolve context, expression
    result

  find: ( target, candidates ) ->
    candidates.find ( candidate ) -> Val.equal target, candidate

  match: ( target, bindings ) ->
    Bindings.find target, Bindings.expand bindings

  expand: ( bindings ) ->
    [ key, rest... ] = Object.keys bindings

    result = []

    if rest.length > 0
      rest = Bindings.expand mask rest, bindings
      if Type.isArray bindings[ key ]
        for value in bindings[ key ]
          for _bindings in rest
            result.push { _bindings..., [ key ]: value }
      else
        for _bindings in rest
          result.push { _bindings..., [ key ]: bindings[ key ] }
    else
      if Type.isArray bindings[ key ]
        for value in bindings[ key ]
          result.push { [ key ]: value }
      else
        result.push bindings

    result  

Grant =

  find: ({ request, authorization }) -> 
    { origin, grants } = authorization
    { resource } = request
    grants.find ( grant ) ->
      ( resource.origin == origin ) &&
        ( resource.name in grant.resources ) &&
        ( request.method in grant.methods )

  resolve: ( context, grant ) ->
    if grant.resolvers?
      { authorization, data } = context
      { resolvers } = authorization
      if grant.resolvers?
        for name in grant.resolvers
          if resolvers[ name ]?
            data[ name ] ?= await resolve context, resolvers[ name ]
          else
            throw failure "bad resolver", name
      data
  
  bind: ( context, grant ) -> Bindings.resolve context, grant.bindings

  match: ( context ) ->
    if ( grant = Grant.find context )?
      await Grant.resolve context, grant
      console.log "Rune Match", context.data
      bindings = await Grant.bind context, grant
      { request } = context
      { resource } = request
      #TODO indicate in the context whether we should expand
      target = expand resource.bindings, context.data
      for key, value of target
        bindings[key] ?= value
      if ( Bindings.match target, bindings )?
        { request..., resource: { resource..., bindings: target }}
      


decode = JSON36.decode

export { issue, verify, match, decode, JSON36 }