import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import * as Type from "@dashkite/joy/type"
import * as Val from "@dashkite/joy/value"
import { Actions } from "@dashkite/enchant/actions"
import { Action } from "@dashkite/enchant/action"
import { Expression } from "@dashkite/enchant/expression"
import { Rule } from "@dashkite/enchant/rules"

filter = ( grants, request ) ->
  grants.filter ( grant ) ->
    ( Actions.resource grant.resources, { request }) &&
      ( Actions.method grant.methods, { request })

resolve = ( resolvers, context ) ->
  Rule.resolve { context: resolvers }, context

buildResolverList = ({ names, resolvers, list }, context ) ->
  for name in names
    if ( value = resolvers[ name ] )?
      if value.requires?
        buildResolverList { names: value.requires, resolvers, list }, context
        delete value.requires
      list.push { name, value... }
    else
      throw new Error "runes: missing resolver [ #{ name } ]"


resolvers = ( authorization, grant, context ) ->
  list = []
  if grant.resolvers?
    buildResolverList(
      { 
        names: grant.resolvers
        resolvers: authorization.resolvers
        list 
      }, context)
  list

bindings = ( bindings, context ) ->
  Action.apply 
    name: "bindings"
    value: bindings
    context

match = ( context ) ->
  { request, authorization } = context
  if request.domain == authorization.domain
    if ( grants = filter ( Val.clone authorization.grants ), request )?
      for grant in grants
        context = await resolve ( resolvers authorization, grant, context ), context
        if grant.any?
          { from, each } = grant.any
          from = Expression.apply from, context
          if Type.isArray from
            matched = from.every ( item ) ->
              await bindings grant.any.bindings, 
                { context..., [ each ]: item }
            if matched then return true
        else
          matched = await bindings ( grant.bindings ? {} ), context
          if matched then return true
  return false
  
export { match }