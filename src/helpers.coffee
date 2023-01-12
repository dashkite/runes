import { confidential } from "panda-confidential"
import { Temporal } from "@js-temporal/polyfill"

Confidential = confidential()

JSON36 = 

  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base36"
      await Confidential.randomBytes 4

JSON64 =

  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base64"
      await Confidential.randomBytes 4
  encode: (value) ->
    Confidential.convert
      from: "utf8"
      to: "base64"
      JSON.stringify value
  
  decode: (value) ->
    JSON.parse Confidential.convert
      from: "base64"
      to: "utf8"
      value

When =
  
  now: -> Temporal.Now.zonedDateTimeISO()

  toISOString: ( t ) -> 
    t.toString
      timeZoneName: "never"
      smallestUnit: "second"

  add: ( t, d ) -> t.add d


export { JSON64, JSON36, Confidential, When }