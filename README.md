# @dashkite/runes

*Authenticated authorization for HTTP*

[![Hippocratic License](https://img.shields.io/badge/license-Hippocratic_3.0-lightgrey.svg)](https://firstdonoharm.dev)

The `@dashkite/runes` package provides a system for generating, verifying, and matching authenticated authorization tokens (runes) for HTTP requests. It uses cryptographic signatures to ensure that the permissions granted are tamper-proof and can be validated securely.

## Features

- Issue cryptographically signed runes.
- Verify the authenticity and expiration of runes.
- Match request context against authorization grants.
- Bind context variables into an authorization structure.
- Integrate with the `@dashkite/enchant` action system.

## Installation

```bash
pnpm install @dashkite/runes
```

## Usage

You can use the `@dashkite/runes` library to issue a rune with specific authorization grants and later verify and match it against an incoming HTTP request.

```coffeescript
import { issue, verify, match } from "@dashkite/runes"

authorization =
  domain: "api.example.com"
  expires: { hours: 1 }
  grants: [
    resources: "documents/*"
    methods: "read"
    bindings:
      "creator.id": "123"
  ]

{ rune, nonce } = await issue { authorization, secret: "supersecret" }

# Later, during a request:
isValid = verify { rune, secret: "supersecret", nonce }

context =
  authorization: authorization
  request:
    domain: "api.example.com"
    resource:
      name: "documents/1"
      bindings:
        "creator.id": "123"

isAllowed = match context
```

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing](docs/testing.md)
