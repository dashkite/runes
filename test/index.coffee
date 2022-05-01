import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { confidential } from "panda-confidential"

Confidential = confidential()

import { issue, verify, JSON64 } from "../src"

authorization =
  domain: "dashkite.io"
  expires: ( new Date ).toISOString()
  grants: [
      resources: [ "team" ]
      methods: [ "get", "put", "delete", "post" ]
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

  print await test "@dashkite/runes",  [

    test "server", [

      test "issuance and verification", await do ->

        { rune, nonce } = await issue authorization, secret
        [_authorization, hash ] = JSON64.decode rune

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
            _authorization.grants[0].resources.push "accounts"
            _rune = JSON64.encode [ _authorization, hash ]
            assert !( verify _rune, secret, nonce )

          
        ] 



        
    ]
  ]