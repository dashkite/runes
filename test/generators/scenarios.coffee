import * as Fn from "@dashkite/joy/function"
import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"

import { rclone } from "./helpers"

import { verify, match, decode } from "../../src"

Actions =

  success:

    verify: ({ rune, secret }) ->
      assert verify { rune..., secret }

    match: ({ request, rune }) ->
      [ authorization ] =  decode rune.rune # welp
      assert await match { request, authorization }

  failure:

    verify: ({ rune, secret }) ->
      assert !( verify { rune..., secret })

    match: ({ request, rune }) ->
      [ authorization ] =  decode rune.rune # welp
      assert !( await match { request, authorization })

      

run = ( scenarios ) ->
  test "@dashkite/runes",
    for scenario in scenarios
      do ( scenario ) ->
        test scenario.name,
          for action in scenario.actions
            do ( action ) ->
              f = Actions[ action.result ][ action.name ]
              test "#{ action.name } #{ action.result}", 
                -> f scenario.context

export { run }

scenario = Fn.curry rclone Fn.rtee ( name, generator, scenarios ) ->
  scenarios.push { name, ( generator actions: [], context: {} )... }

export { scenario }

action = Fn.curry rclone Fn.rtee ( action, scenario ) ->
  scenario.actions.push { name: action, result: "success" }

export { action }

fail = Fn.curry rclone Fn.rtee ( action, scenario ) ->
  scenario.actions.push { name: action, result: "failure" }

export { fail }

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
