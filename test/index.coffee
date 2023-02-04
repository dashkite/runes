import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import * as Fn from "@dashkite/joy/function"
import { confidential } from "panda-confidential"

import "./local-storage"

import * as API from "./generators/apis"
import * as Scenarios from "./generators/scenarios"

import { issue, verify, match, encode, decode } from "../src"

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

    make: ({ aspect, valid, benchmark }) ->

      authorization = {}

      authorization.domain = "acme.org"

      if ( valid || aspect != "expiry" )
        authorization.expires = days: 1
      else
        authorization.expires = days: -1

      if aspect != "malformed authorization"
        authorization.grants = []
        authorization.grants.push
          resources: [ "foo" ]
          methods: [ "get" ]
          bindings: bar: "baz"


      # TODO randomize so that it's not always the same thing
      if benchmark?
        for i in [1..100]
          authorization.grants.push
            resources: [ "foo" ]
            methods: [ "get" ]
            bindings: bar: "baz"

      rune = if aspect != "forged"
        await issue { authorization, secret: Secrets.guardian }
      else
        await issue { authorization, secret: Secrets.forged }

      if aspect == "tamper"
        [ authorization, hash ] = decode rune.rune # welp
        authorization.grants[0].methods.push "put"
        rune =
          rune: encode [ authorization, hash ]
          nonce: rune.nonce

      if aspect == "malformed rune"
        rune = "123456789"

      scenario = actions: [], context: { rune }

      scenario.name = switch aspect
        when "forged" then "forged rune"
        when "tamper" then "tampered authority"
        when "benchmark" then "benchmark"
        when "malformed rune", "malformed authority" then aspect
        else
          if valid
            "valid #{ aspect ? 'request' }"
          else
            "invalid #{ aspect ? 'request' }"

      switch aspect
        when "expiry", "forged", "tamper", "malformed rune"
          scenario.actions.push { name: "verify", result: "failure" }
        when "benchmark"
          scenario.actions.push { name: "benchmark", result: "success" }
        else
          scenario.actions.push { name: "verify", result: "success" }
          if valid
            scenario.actions.push { name: "match", result: "success" }
          else
            scenario.actions.push { name: "match", result: "failure" }

      scenario.context.secret = Secrets.guardian

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

      scenario.context.request =
        domain: domain
        resource:
          name: resource
          bindings: bindings           
        method: method
      
      scenario
  
  scenarios = [ await Scenario.make { valid: true } ]
  
  for aspect in [ "domain", "resource", "method", "binding", "expiry" ]
    scenarios.push await Scenario.make { aspect, valid: false }

  for aspect in [ "forged", "tamper", "malformed rune", "malformed authorization" ]
    scenarios.push await Scenario.make { aspect, valid: false }

  scenarios.push await Scenario.make { aspect: "benchmark", valid: true }

  print await Scenarios.run scenarios