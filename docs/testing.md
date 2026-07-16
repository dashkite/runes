# Testing

This document details the testing strategy and execution instructions for the `@dashkite/runes` module.

## Strategy

The test suite is built on top of `@dashkite/amen` and `@dashkite/assert`. Tests validate the lifecycle of a rune: generating a valid signature, rejecting tampered payloads, enforcing expiration times, and correctly evaluating complex matching conditions with dynamic bindings. Time manipulation is often required to test expiration boundaries effectively.

## Running Tests

To run the full suite of automated tests for the package, you can invoke the test command using Genie.

```bash
npx genie test
```
