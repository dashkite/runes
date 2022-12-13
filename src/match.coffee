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
  console.log "RUNES RESOLVERS", resolvers
  Rule.resolve { context: resolvers }, context

buildResolverList = ({ names, resolvers, list }, context ) ->
  for name in names
    if ( value = resolvers[ name ] )?
      if value.requires?
        buildResolverList { names: value.requires, resolvers, list }, context
        delete value.requires
      value.action.value.authorization = context.request.authorization
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
  Actions.bindings bindings, context

match = ( context ) ->
  { request, authorization } = context
  if request.domain == authorization.domain
    if ( grant = find authorization.grants, request )?
      bindings ( grant.bindings ? {} ),
        await resolve ( resolvers authorization, grant, context ), context
    else false
  else false
  
export { match }