import * as Fn from "@dashkite/joy/function"
import { rclone } from "./helpers"

import { issue } from "../../src"

domain = Fn.curry rclone Fn.rtee ( domain, description ) ->
  description.domain = domain

export { domain }

expires = Fn.curry rclone Fn.rtee ( expires, description ) ->
  description.expires = expires

export { expires }

grant = Fn.curry rclone Fn.rtee ( generator, description ) ->
  description.grants ?= []
  description.grants.push generator {}

export { grant }

resolvers = Fn.curry rclone Fn.rtee ( resolvers, grant ) ->
  grant.resolvers = resolvers

export { resolvers }

resources = Fn.curry rclone Fn.rtee ( resources, grant ) ->
  grant.resources = resources

export { resources }

methods = Fn.curry rclone Fn.rtee ( methods, grant ) ->
  grant.methods = methods

export { methods }

bindings = Fn.curry rclone Fn.rtee ( bindings, grant ) ->
  grant.bindings = bindings

export { bindings }

any = Fn.curry rclone Fn.rtee ( any, grant ) ->
  grant.any = any

export { any }

seal = Fn.curry ( secret, authorization ) ->
  issue { authorization, secret }

export { seal }

make = ( generator ) -> -> generator {}

export { make }
