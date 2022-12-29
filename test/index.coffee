import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import {sleep} from "panda-parchment"
import "./local-storage"

import { confidential } from "panda-confidential"

Confidential = confidential()

import { issue, verify, match, bind } from "../src"
import { JSON36 } from "../src/helpers"

import api from "./api"
import authorization from "./authorization"
import bound from "./bound"

globalThis.Sky =
  fetch: ( request ) ->
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
  [ _authorization, hash ] = JSON36.decode rune

  print await test "@dashkite/runes",  [

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
            bindings:
              workspace:
                "acme"
          method: "get"
        assert await match { request, authorization }

      test "wildcard-match", ->
        request =
          domain: "foo.dashkite.io"
          resource:  
            name: "workspace-subscriptions"
            bindings: 
              workspace: "acme"
              product: "graphene"
          method: "get"
        assert await match { request, authorization }

      test "wildcard-failure", ->
        request =
          domain: "foo.dashkite.io"
          resource:  
            name: "workspace-subscriptions"
            bindings: 
              workspace: "evil"
              product: "graphene"
          method: "get"
        console.log "wildcard-failure", 
          await match { request, authorization }
        assert !( await match { request, authorization })
      
      test "match failure", ->
        request =
          domain: "foo.dashkite.io"
          resource:
            name: "workspace"
            bindings: workspace: "evil"
          method: "get"
        assert !( await match { request, authorization  })
    ]

    test "bind", [

      test "match", ->
        request =
          domain: "foo.dashkite.io"
          resource:  
            name: "workspace"
            bindings:
              workspace:
                "acme"
          method: "get"
        result = await bind { authorization, request }
        assert.deepEqual result, bound

    ]

  ]
