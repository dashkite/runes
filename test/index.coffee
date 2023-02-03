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

  authorization = do Rune.make Fn.pipe [
    Rune.domain "acme.org"
    Rune.expires days: 30
    Rune.grant Fn.pipe [
      Rune.resources API.match /^foo/, api
      Rune.methods [ "get" ]
      Rune.bindings bar: "baz"
    ]
  ]

  rune = await Rune.seal Secrets.guardian, authorization

  scenarios = do Scenarios.make Fn.pipe [
    Scenarios.scenario "valid binding", Fn.pipe [
      Scenarios.action "verify"
      Scenarios.action "match"
      Scenarios.authorization authorization
      Scenarios.secret Secrets.guardian
      Scenarios.rune rune
      Scenarios.request
        domain: "acme.org"
        resource:
          name: "foo"
          bindings: bar: "baz"
        method: "get"
    ]
  ]

  print await Scenarios.run scenarios