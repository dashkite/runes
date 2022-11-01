import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import { Actions } from "@dashkite/enchant/actions"
import { Rule } from "@dashkite/enchant/rules"

find = ( grants, request ) ->
  grants.find ( grant ) ->
    ( Actions.resource grant.resources, { request }) &&
      ( Actions.method grant.methods, { request })

resolve = ( resolvers, context ) ->
  Rule.resolve context: resolvers, context

resolvers = ( authorization, grant ) ->
  for resolver in grant.resolvers
    if ( value = authorization.resolvers[ resolver ] )?
      {
        name: resolver
        value...
      }
    else
      throw new Error "runes: missing resolver [ #{ resolver } ]"

bindings = ( bindings, context ) ->
  Actions.bindings bindings, context

match = ( context ) ->
  { request, authorization } = context
  if request.domain == authorization.domain
    if ( grant = find authorization.grants, request )?
      bindings grant.bindings,
        await resolve ( resolvers authorization, grant ), context
    else false
  else false
  
export { match }