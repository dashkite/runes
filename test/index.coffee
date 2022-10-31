import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import {sleep} from "panda-parchment"
import "./local-storage"

import { confidential } from "panda-confidential"

Confidential = confidential()

import { issue, verify, match, JSON36 } from "../src"
import { store, lookup } from "../src/client"

import api from "./api"
import authorization from "./authorization"

fetch = ( request ) ->
  # TODO possibly switch back to target using helper 
  #      to derive target from resource?
  { resource } = request
  switch resource.name
    when "description"
      content: api
    when "workspace"
      content: address: "acme"
    when "workspaces"
      content: [ { address: "acme" }, { address: "evilcorp" }]
    when "account"
      content: address: "alice"
    when "workspace-subscriptions"
      content: subscription: "active"
    else
      throw new Error "oops that's not a pretend resource!"

do ->

  secret = Confidential.convert
    from: "bytes"
    to: "base64"
    await Confidential.randomBytes 16

  forged = Confidential.convert
    from: "bytes"
    to: "base64"
    await Confidential.randomBytes 16

  { rune, nonce } = await issue { authorization, secret }

  print await test "@dashkite/runes",  [

    test "server", await do ->

      [ _authorization, hash ] = JSON36.decode rune
      
      [
        test "issuance", [

          test "hash should always be 32 bytes", ->
            assert.equal 32,
              Confidential.convert
                from: "base64"
                to: "bytes"
                hash
              .length
        ]

        test "verification", [

          test "rune should verify with correct secret and nonce", ->
            assert verify { rune, secret, nonce }
          
          test "rune should fail to verify with forged secret", ->
            assert !( verify { rune, secret: forged, nonce } )

          test "rune should fail when expired"

          test "authorization should be unchanged", ->
            # TODO check expires as well
            # expires will have converted to an ISO string, so we check
            # the domain and grant instead
            # we can check expires too if we make temporal helpers
            # into a separate module, importable
            assert.equal authorization.domain, _authorization.domain
            assert.deepEqual authorization.grants, _authorization.grants

          test "rune should fail to verify with altered authorization", ->
            _authorization.grants[0].resources.push "workspaces"
            _rune = JSON36.encode [ _authorization, hash ]
            assert !( verify { rune: _rune, secret, nonce } )
        ]
        
        test "match", [

          test "match", ->
            request =
              domain: "foo.dashkite.io"
              resource:  
                name: "workspace"
                bindings: workspace: "acme"
              method: "get"
            assert ( request = await match { fetch, request, authorization } )?
            assert.equal "workspace", request.resource.name
            assert.equal "acme", request.resource.bindings.workspace

          test "wildcard-match", ->
            request =
              domain: "foo.dashkite.io"
              resource:  
                name: "workspace-subscriptions"
                bindings: 
                  workspace: "acme"
                  product: "graphene"
              method: "get"
            assert ( request = await match { fetch, request, authorization } )?
            assert.equal "workspace-subscriptions", request.resource.name
            assert.equal "graphene", request.resource.bindings.product

          test "wildcard-failure", ->
            request =
              domain: "foo.dashkite.io"
              resource:  
                name: "workspace-subscriptions"
                bindings: 
                  workspace: "evil"
                  product: "graphene"
              method: "get"
            assert !( await match { fetch, request, authorization } )?
          
          test "match failure", ->
            request =
              domain: "foo.dashkite.io"
              resource:
                name: "workspace"
                bindings: workspace: "evil"
              method: "get"
            assert !( await match { fetch, request, authorization  })?
        ]
      ]

    test "client", [

      test "store", ->
        assert.equal null, store { rune, nonce }

      test "lookup", ->
        result = lookup
          identity: "alice@acme.org"
          domain: "foo.dashkite.io"
          resource: "workspace"
          method: "get"
        assert result?
        assert.equal result.rune, rune
        assert.equal result.nonce, nonce

      test "lookup failure", ->
        result = lookup
          identity: "bob@acme.org"
          domain: "foo.dashkite.io"
          resource: "workspace"
          method: "get"
        assert !result?
    ]

        
  ]