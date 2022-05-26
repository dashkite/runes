import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"
import {sleep} from "panda-parchment"

import { confidential } from "panda-confidential"

Confidential = confidential()

import { issue, verify, match, store, lookup, JSON36 } from "../src"
import api from "./api"

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
    else
      throw new Error "oops that's not a pretend resource!"

authorization =

  origin: "https://foo.dashkite.io"
  expires:
    days: 30
  identity: "alice@acme.org"
  resolvers:
    account:
      request:
        resource: 
          name: "account"
          bindings: email: "alice@acme.org"
    workspaces:
      request:
        resource:
          name: "workspaces"
          bindings: account: "${ account.address }"

  grants: [

      resources: [ "account" ]
      bindings: email: "alice@acme.org"
      methods: [ "get" ]

    ,

      resources: [ "workspaces" ]
      resolvers: [ "account" ]
      bindings: account: "${ account.address }"
      methods: [ "get" ]

    ,

      resources: [ "workspace" ]
      resolvers: [ "workspaces" ]
      bindings: workspace: "${ workspaces[*].address }"
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
            assert.deepEqual authorization, _authorization

          test "rune should fail to verify with altered authorization", ->
            _authorization.grants[0].resources.push "workspaces"
            _rune = JSON36.encode [ _authorization, hash ]
            assert !( verify { rune: _rune, secret, nonce } )
        ]
        
        test "match", [

          test "match", ->
            request =
              resource:  
                origin: "https://foo.dashkite.io"
                name: "workspace"
                bindings: workspace: "acme"
              method: "get"
            assert ( request = await match { fetch, request, authorization } )?
            assert.equal "workspace", request.resource.name
            assert.equal "acme", request.resource.bindings.workspace
            
          
          test "match failure", ->
            request =
              resource:
                origin: "https://foo.dashkite.io"
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
          origin: "https://foo.dashkite.io"
          resource: "workspace"
          method: "get"
        assert result?
        assert.equal result.rune, rune
        assert.equal result.nonce, nonce

      test "lookup failure", ->
        result = lookup
          identity: "bob@acme.org"
          origin: "https://foo.dashkite.io"
          resource: "workspace"
          method: "get"
        assert !result?
    ]

        
  ]