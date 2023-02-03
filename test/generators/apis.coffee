import * as Fn from "@dashkite/joy/function"

import { rclone } from "./helpers"

resource = Fn.curry rclone Fn.rtee ( name, generator, description ) ->
  description.resources ?= {}
  description.resources[ name ] = generator {}

export { resource }

template = Fn.curry rclone Fn.rtee ( template, resource ) ->
  resource.template = template

export { template }

method = Fn.curry rclone Fn.rtee ( method, generator, resource ) ->
  resource.methods ?= {}
  resource.methods[ method ] = generator request: {}, response: {}

export { method }

ok = Fn.curry rclone Fn.rtee ( method ) ->
  method.response.status = [ 200 ]

export { ok }

json = Fn.curry rclone Fn.rtee ( method ) ->
  method.response["content-type"] = [ "application/json" ]

export { json }

match = Fn.curry ( re, api ) ->
  Object.entries api.resources
    .map ([ name ]) -> name
    .filter ( name ) -> re.test name

export { match }

make = ( generator ) -> -> generator {}

export { make }
