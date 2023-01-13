import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import * as Type from "@dashkite/joy/type"
import * as Val from "@dashkite/joy/value"
import { Actions } from "@dashkite/enchant/actions"
import { Action } from "@dashkite/enchant/action"
import { Expression } from "@dashkite/enchant/expression"
import { Rule } from "@dashkite/enchant/rules"

Grants =
  filter: ( grants, request ) ->
    grants
      .filter ( grant ) ->
        ( Actions.resource grant.resources, { request }) &&
          ( Actions.method grant.methods, { request })
      
Resolvers =

  dictionaryToList: ( dictionary ) ->
    Object
      .entries dictionary
      .map ([ name, value ]) -> { name, value... }

  expand: ( names, resolvers ) ->
    result = {}
    for name in names
      resolver = resolvers[ name ]
      result[ name ] = resolver
      if resolver.requires?
        result = { 
          result...
          ( Resolvers.expand resolver.requires, resolvers )...
        }
    Resolvers.dictionaryToList result

  apply: ( resolvers, context ) ->
    Rule.resolve { context: resolvers }, context

Bindings =

  match: ( target, context ) ->
    if target?
      { request } = context
      { resource } = request
      { bindings } = resource
      
      Object.entries ( Expression.apply target, context )
        .every ([ key, value ]) ->
          if bindings[key]? && value?
            Val.equal bindings[ key ], value
          else
            false
    else true

match = ( context ) ->
  context = { context... }
  { request, authorization } = context
  if request.domain == authorization.domain
    grants = Grants.filter ( authorization.grants ), request
    for grant in grants
      if grant.resolvers?
        resolvers = Resolvers.expand grant.resolvers, authorization.resolvers
        await Resolvers.apply resolvers, context
      if grant.any?
        matched = ( Expression.apply grant.any.from, context )
          .some ( value ) ->
            Bindings.match grant.any.bindings, 
              { context..., [ grant.any.each ]: value }
        if matched then return true
      else
        matched = Bindings.match grants.bindings, context
        if matched then return true
    return false

bind = ( authorization, context ) ->

  bound = Val.clone authorization
  context = { context... }

  if authorization.resolvers?
    resolvers = Resolvers.dictionaryToList authorization.resolvers
    await Resolvers.apply resolvers, context
    delete bound.resolvers 

  { grants } = bound
  for grant in grants
    if grant.resolvers?
      delete grant.resolvers
    if grant.any?
      grant.any.from = Expression.apply grant.any.from, context 
    else
      grant.bindings = Expression.apply grant.bindings, context
  bound

export { match, bind }
