# Recipes

This document provides a sequential guide to mastering the `@dashkite/runes` module. The examples progress from fundamental token issuance to advanced capability-based authorization schemes and lower-level cryptographic primitives.

## Issuing and Verifying a Rune

The most fundamental task when working with capabilities is issuing a secure token to a client and later verifying its authenticity when the client makes a request. The `@dashkite/runes` library enables this by generating a Message Authentication Code (MAC) derived from your authorization grants, an expiration time, and a secret key.

1. Define an authorization object with a target domain, expiration time, and an array of grants.
2. Provide your server-side cryptographic secret.
3. Call the `issue` function to generate the signed rune and its associated nonce.
4. When a request arrives, extract the rune and nonce, and call `verify` to confirm it is authentic and unexpired.

```coffeescript
import { issue, verify } from "@dashkite/runes"

authorization =
  domain: "api.example.com"
  expires: { hours: 2 }
  grants: [
    resources: "photos/*"
    methods: "read"
  ]

secret = "my-secure-secret-key"

# Issue the rune for the client
{ rune, nonce } = await issue { authorization, secret }

# --- Later, during an incoming request ---
# Assume `incomingRune` and `incomingNonce` are extracted from headers
isValid = verify { rune: incomingRune, secret, nonce: incomingNonce }

if isValid
  console.log "The rune is authentic and valid."
else
  console.log "The rune is invalid or expired."
```

## Matching a Request Context

Once a rune is verified, the application must confirm that the requested action is actually permitted by the token's enclosed grants. The `match` function enables this by evaluating the grants inside the authorization object against the incoming request's actual resource, method, and variable bindings.

1. Construct a context object containing both the decoded `authorization` and the `request`.
2. Define the `domain`, `resource`, and `method` within the request.
3. Use the `match` function to evaluate the context.

```coffeescript
import { match } from "@dashkite/runes"

authorization =
  domain: "api.example.com"
  grants: [
    resources: "photos/*"
    methods: [ "read", "write" ]
  ]

context =
  authorization: authorization
  request:
    domain: "api.example.com"
    resource: 
      name: "photos/holiday.jpg"
      bindings: {}
    method: "write"

isAllowed = match context

if isAllowed
  console.log "Request is authorized by the rune's grants."
else
  console.log "Request is denied."
```

## Binding Dynamic Context Variables

In complex policy-based authorization schemes, grants may contain abstract expressions or resolvers that need concrete values before they can be fully evaluated. The `bind` function enables developers to resolve these dynamic bindings against a specific environment context.

1. Define an authorization object containing dynamic `resolvers` or context-dependent expressions.
2. Construct an environment context providing the necessary data.
3. Call the `bind` function to evaluate the resolvers and produce a finalized, concrete authorization object.

```coffeescript
import { bind } from "@dashkite/runes"

authorization =
  domain: "api.example.com"
  grants: [
    resources: "creator/{creator.id}/profile"
    methods: "read"
  ]
  resolvers:
    "creator.id":
      requires: [ "request.headers.authorization" ]
      resolve: ( context ) ->
        # Decode the creator ID from the request headers
        "12345"

context =
  request:
    headers:
      authorization: "Bearer some-token"

# Generate a new authorization object with expressions fully resolved
boundAuthorization = await bind authorization, context
```

## Manual Rune Generation and Encoding

While `issue` and `verify` handle standard workflows, arcane or highly specialized use cases may require manual signature generation or structural data encoding. The library exposes its low-level cryptographic primitives—`make`, `encode`, and `decode`—to facilitate deterministic generation and custom serialization.

1. Use `encode` to securely serialize and Base64-encode raw structural data.
2. Provide a predetermined nonce and call `make` to deterministically generate a rune MAC.
3. Use `decode` to parse the encoded string back into its original JSON representation.

```coffeescript
import { make, encode, decode } from "@dashkite/runes"

rawPayload = 
  domain: "api.example.com"
  grants: []
  expires: "2026-12-31T23:59:59Z"

# 1. Encode custom structural data
encodedData = encode rawPayload

# 2. Deterministically generate a rune with a known nonce
secret = "my-secure-secret-key"
predeterminedNonce = "fixed-nonce-value"

{ rune, nonce } = make rawPayload, secret, predeterminedNonce

# 3. Decode the rune back into its structural payload and signature components
[ parsedPayload, cryptographicHash ] = decode rune
```
