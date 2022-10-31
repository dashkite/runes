import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import { Actions } from "@dashkite/enchant/actions"
import { Rule } from "@dashkite/enchant/rules"

find = ( grants ) ->
  authorization.grants.find ( grant ) ->
    ( Actions.resource grant.resources, { request }) &&
      ( Actions.method grant.methods, { request })

resolve = ( resolvers, context ) ->
  Rule.resolve context: resolvers, context

resolvers = ( authorization, grant ) ->
  for resolver in grant.resolvers
    authorization.resolvers[ resolver ]

bindings = ( bindings, context ) ->
  Object.entries bindings
    .every ([ key, value ]) ->
      context[ key ] == value

match = ( context ) ->
  { request, authorization } = context
  if request.domain == authorization.domain
    if ( grant = find authorization.grants )?
      bindings grant.bindings,
        await resolve ( resolvers authorization, grant ), context
  
export { match }