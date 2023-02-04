import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as Fn from "@dashkite/joy/function"
import { confidential } from "panda-confidential"

import "./local-storage"

import * as API from "./generators/apis"
import * as Rune from "./generators/runes"
import * as Scenarios from "./generators/scenarios"

import { verify, match } from "../src"

Confidential = confidential()

do ->

  Secrets =

    guardian: Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 16
    
    forged:  Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 16

  # print await test "@dashkite/runes"

  api = do API.make Fn.pipe [
    API.resource "foo", Fn.pipe [
      API.template "/foo/{bar}"
      API.method "get", Fn.pipe [
        API.ok
        API.json
      ]
    ]
    API.resource "bar", Fn.pipe [
      API.template "/bar/{foo}"
      API.method "get", Fn.pipe [
        API.ok
        API.json
      ]
    ]
  ]

  Scenario =

    make: ({ aspect, valid }) ->

      name = if aspect == "forged"
        "forged request"
      else if valid
        "valid #{ aspect ? 'request' }"
      else
        "invalid #{ aspect ? 'request' }"

      Generators =
        rune: []
        scenario: []

      Generators.rune.push Rune.domain "acme.org"

      Generators.rune.push if ( valid || aspect != "expiry" )
        Rune.expires days: 1
      else
        Rune.expires days: -1

      Generators.rune.push Rune.grant Fn.pipe [
        Rune.resources API.match /^foo/, api
        Rune.methods [ "get" ]
        Rune.bindings bar: "baz"
      ]

      if aspect != "forged"
        Generators.rune.push Rune.seal Secrets.guardian
      else
        Generators.rune.push Rune.seal Secrets.forged
      
      rune = await do Rune.make Fn.pipe Generators.rune

      if valid || !( aspect in [ "expiry", "forged" ])
        Generators.scenario.push Scenarios.action "verify"
      else
        Generators.scenario.push Scenarios.fail "verify"

      if valid
        Generators.scenario.push Scenarios.action "match"
      else if !( aspect in [ "expiry", "forged" ])
        Generators.scenario.push Scenarios.fail "match" 

      # Generators.scenario.push Scenarios.authorization authorization
      Generators.scenario.push Scenarios.secret Secrets.guardian
      Generators.scenario.push Scenarios.rune rune

      domain = if ( valid || aspect != "domain" )
        "acme.org"
      else
        "evil.com"

      resource = if ( valid || aspect != "resource" )
        "foo"
      else
        "bar"

      method = if ( valid || aspect != "method" )
        "get"
      else
        "put"
      
      bindings = if ( valid || aspect != "binding" )
        bar: "baz"
      else
        bar: "zab"

      Generators.scenario.push Scenarios.request
        domain: domain
        resource:
          name: resource
          bindings: bindings           
        method: method
      
      Scenarios.scenario name, Fn.pipe Generators.scenario
  
  _scenarios = [ await Scenario.make { valid: true } ]
  
  for aspect in [ "domain", "resource", "method", "binding", "expiry" ]
    _scenarios.push await Scenario.make { aspect, valid: false }

  _scenarios.push await Scenario.make { aspect: "forged", valid: false }
  
  # console.log _scenarios
  scenarios = do Scenarios.make Fn.pipe _scenarios

  print await Scenarios.run scenarios