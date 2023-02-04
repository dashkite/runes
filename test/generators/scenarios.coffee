import * as Fn from "@dashkite/joy/function"
import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"

import * as Time from "@dashkite/joy/time"

import { rclone } from "./helpers"

import { verify, match, decode } from "../../src"

Actions =

  success:

    verify: ({ rune, secret }) ->
      assert verify { rune..., secret }

    match: ({ request, rune }) ->
      [ authorization ] =  decode rune.rune # welp
      assert await match { request, authorization }

    benchmark: ({ request, rune, secret }) ->
      ms = await Time.benchmark ->
        assert verify { rune..., secret }
        [ authorization ] =  decode rune.rune # welp
        assert await match { request, authorization }
      assert ms < 100 # milliseconds

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
        name = if scenario.benchmark?
          "#{ scenario.name } benchmark"
        else
          scenario.name
        test name,
          for action in scenario.actions
            do ( action ) ->
              f = Actions[ action.result ][ action.name ]
              test "#{ action.name } #{ action.result}", -> f scenario.context

export { run }