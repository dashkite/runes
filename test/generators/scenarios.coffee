import * as Fn from "@dashkite/joy/function"
import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"

import { rclone } from "./helpers"

import { verify, match } from "../../src"

Actions =

  verify: ({ rune, secret }) ->
    assert verify { rune..., secret }

  match: ({ request, authorization }) ->
    assert await match { request, authorization }

run = ( scenarios ) ->
  test "@dashkite/runes",
    for scenario in scenarios
      do ( scenario ) ->
        test scenario.name,
          for action in scenario.actions
            test action, -> Actions[ action ] scenario.context

export { run }

scenario = Fn.curry rclone Fn.rtee ( name, generator, scenarios ) ->
  scenarios.push { name, ( generator actions: [], context: {} )... }

export { scenario }

action = Fn.curry rclone Fn.rtee ( action, scenario ) ->
  scenario.actions.push action

export { action }

authorization = Fn.curry rclone Fn.rtee ( authorization, { context } ) ->
  context.authorization = authorization

export { authorization }

secret = Fn.curry rclone Fn.rtee ( secret, { context } ) ->
  context.secret = secret

export { secret }

rune = Fn.curry rclone Fn.rtee ( rune, { context } ) ->
  context.rune = rune

export { rune }

request = Fn.curry rclone Fn.rtee ( request, { context } ) ->
  context.request = request

export { request }

make = ( generator ) -> -> generator []

export { make }
