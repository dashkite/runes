import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import * as Type from "@dashkite/joy/type"
import { Actions } from "@dashkite/enchant/actions"
import { Action } from "@dashkite/enchant/action"
import { Expression } from "@dashkite/enchant/expression"
import { Rule } from "@dashkite/enchant/rules"

find = ( grants, request ) ->
  grants.find ( grant ) ->
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
    if ( grant = find authorization.grants, request )?
      context = await resolve ( resolvers authorization, grant, context ), context
      if grant.any?
        { from, each } = grant.any
        from = Expression.apply from, context
        if Type.isArray from
          from.every ( item ) ->
            bindings grant.any.bindings, 
              { context..., [ each ]: item }
        else
          false
      else
        bindings ( grant.bindings ? {} ), context
    else false
  else false
  
export { match }