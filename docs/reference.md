# Reference

This document provides a comprehensive API reference for the `@dashkite/runes` module, detailing each function's purpose, arguments, and return types, alongside practical usage examples.

## issue

$issue: ( \{ authorization, secret \} ) \rightarrow \{ rune, nonce \}$

Issues a new signed rune based on an `authorization` object and a `secret` key. The `authorization` object MUST contain an `expires` property, which can be an object specifying a duration (e.g., `{ hours: 1 }`) or a strict ISO 8601 timestamp string. A cryptographic `nonce` is generated automatically during this process to ensure uniqueness and mitigate replay attacks.

- `authorization`: An object describing the capabilities, such as the `domain` and the array of `grants`.
- `secret`: A string or buffer containing the secret key used for computing the cryptographic Message Authentication Code (MAC).

Returns an object containing the generated `rune` string and its associated `nonce`.

```coffeescript
import { issue } from "@dashkite/runes"

authorization = 
  domain: "api.example.com"
  expires: { hours: 24 }
  grants: [
    resources: "articles/*"
    methods: "read"
  ]

{ rune, nonce } = await issue { authorization, secret: "super-secret" }
```

## make

$make: ( authorization, secret, nonce ) \rightarrow \{ rune, nonce \}$

Creates a rune deterministically given a specific `authorization` object, `secret`, and `nonce`. Unlike `issue`, which generates a random nonce and sets expiration timestamps, `make` is a lower-level primitive utilized by both `issue` and `verify` to compute the deterministic MAC.

- `authorization`: The capability payload detailing grants and expiration bounds.
- `secret`: The secret key used for signing the payload.
- `nonce`: A unique cryptographic nonce string.

Returns an object containing the generated `rune` and the original `nonce`.

```coffeescript
import { make } from "@dashkite/runes"

{ rune, nonce } = make authorization, "super-secret", "base36-nonce-string"
```

## verify

$verify: ( \{ rune, secret, nonce \} ) \rightarrow boolean$

Verifies the integrity and time validity of a rune. It decodes the rune, extracts the enclosed authorization payload, and checks that the `expires` timestamp has not passed. Then, it utilizes the `make` primitive to recompute the signature using the original `secret` and `nonce`, ensuring the payload has not been tampered with.

- `rune`: The encoded rune string provided by a client request.
- `secret`: The secret key used by the issuing authority.
- `nonce`: The nonce generated during the initial issuance.

Returns `true` if the rune is mathematically authentic and strictly unexpired; `false` otherwise.

```coffeescript
import { verify } from "@dashkite/runes"

isValid = verify { rune: "base64-string", secret: "super-secret", nonce: "base36-nonce" }
```

## match

$match: ( context ) \rightarrow boolean$

Evaluates an authorization context against the capability grants specified within a rune. The `context` argument should contain the original `authorization` object and the incoming `request`. The function enforces that the request's domain matches the authorization's domain, filters grants using `@dashkite/enchant`, and evaluates dynamic resolvers and bindings.

- `context`: An object containing the `authorization` and `request` data (including the `resource` and `method`).

Returns `true` if any grant in the authorization permits the request based on matching resources, methods, and specific variable bindings. Returns `false` otherwise.

```coffeescript
import { match } from "@dashkite/runes"

context =
  authorization: decodedAuthorization
  request:
    domain: "api.example.com"
    resource: 
      name: "articles/1"
      bindings: {}
    method: "read"

isAuthorized = match context
```

## bind

$bind: ( authorization, context ) \rightarrow authorization$

Resolves dynamic bindings and expressions within an `authorization` object based on a provided `context`. It iterates over any specified resolvers and updates the grant conditions with concrete values extracted from the context, returning a new structural clone.

- `authorization`: The initial capability object containing abstract expressions or dynamic resolvers.
- `context`: The environment data (such as the incoming request) used to concretely evaluate expressions.

Returns a new, fully bound `authorization` object.

```coffeescript
import { bind } from "@dashkite/runes"

boundAuthorization = await bind authorization, { request: incomingRequest }
```

## encode

$encode: ( value ) \rightarrow string$

Serializes a provided structural `value` as JSON and securely encodes it into a Base64 format using the `panda-confidential` library. 

- `value`: Any JSON-serializable structure (e.g., arrays or objects).

Returns the Base64-encoded string.

```coffeescript
import { encode } from "@dashkite/runes"

encodedString = encode [ { some: "data" }, "hash" ]
```

## decode

$decode: ( value ) \rightarrow any$

Decodes a Base64-encoded string back into its original JSON string, and parses it into its structural representation.

- `value`: The Base64-encoded string to decode.

Returns the parsed data structure (typically an array or object).

```coffeescript
import { decode } from "@dashkite/runes"

[ payload, signature ] = decode encodedString
```
