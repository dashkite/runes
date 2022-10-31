import { confidential } from "panda-confidential"
import { Temporal } from "@js-temporal/polyfill"

Confidential = confidential()

JSON36 =

  nonce: ->
    Confidential.convert
      from: "bytes"
      to: "base36"
      await Confidential.randomBytes 4
  encode: (value) ->
    Confidential.convert
      from: "utf8"
      to: "base36"
      JSON.stringify value
  
  decode: (value) ->
    JSON.parse Confidential.convert
      from: "base36"
      to: "utf8"
      value

When =
  
  now: -> Temporal.Now.zonedDateTimeISO()

  toISOString: ( t ) -> 
    t.toString
      timeZoneName: "never"
      smallestUnit: "second"

  add: ( t, d ) -> t.add d


export { JSON36, Confidential, When }