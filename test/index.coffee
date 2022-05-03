import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { confidential } from "panda-confidential"

Confidential = confidential()

import fetch from "node-fetch"
globalThis.fetch ?= fetch
global.Request ?= fetch.Request

import { issue, verify, match, store, lookup, JSON36 } from "../src"

authorization =
  origin: "https://workspaces.dashkite.io"
  expires: ( new Date ).toISOString()
  grants: [
      resources: [ "account-workspaces" ]
      bindings: account: "acme"
      methods: [ "get" ]
  ]

do ->

  secret = Confidential.convert
    from: "bytes"
    to: "base64"
    await Confidential.randomBytes 16

  forged = Confidential.convert
    from: "bytes"
    to: "base64"
    await Confidential.randomBytes 16

  { rune, nonce } = await issue authorization, secret

  print await test "@dashkite/runes",  [

    test "server", [

      test "issuance and verification", await do ->

        [_authorization, hash ] = JSON36.decode rune

        [

          test "hash should always be 32 bytes", ->
            assert.equal 32,
              Confidential.convert
                from: "base64"
                to: "bytes"
                hash
              .length

          test "rune should verify with correct secret and nonce", ->
            assert verify rune, secret, nonce
          
          test "rune should fail to verify with forged secret", ->
            assert !( verify rune, forged, nonce )

          test "authorization should be unchanged", ->
            assert.deepEqual authorization, _authorization

          test "rune should fail to verify with altered authorization", ->
            _authorization.grants[0].resources.push "workspaces"
            _rune = JSON36.encode [ _authorization, hash ]
            assert !( verify _rune, secret, nonce )

          test "match", ->
            request =
              url:  "https://workspaces.dashkite.io/accounts/acme/workspaces"
              method: "get"
            assert await match request, authorization
          
          test "match failure", ->
            request =
              url:  "https://workspaces.dashkite.io/accounts/fubar/workspaces"
              method: "get"
            assert !( await match request, authorization )
        ] 

    test "client", [

      test "store", ->
        assert.equal null, store { rune, nonce }

      test "lookup", ->
        result = lookup
          origin: "https://workspaces.dashkite.io"
          resource: "account-workspaces"
          bindings: account: "acme"
          method: "get"
        assert result?
        assert.equal result.rune, rune
        assert.equal result.nonce, nonce

      test "lookup failure", ->
        result = lookup
          origin: "https://workspaces.dashkite.io"
          resource: "team"
          bindings: team: "foo"
          method: "put"
        assert !result?
    ]

        
    ]
  ]