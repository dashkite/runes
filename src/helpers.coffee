import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import { generic } from "@dashkite/joy/generic"
import { confidential } from "panda-confidential"
import { Temporal } from "@js-temporal/polyfill"

Confidential = confidential()

Nonce = 
  generate: ->
    Confidential.convert
      from: "bytes"
      to: "base36"
      await Confidential.randomBytes 4

encode = (value) ->
  Confidential.convert
    from: "utf8"
    to: "base36"
    JSON.stringify value

decode = (value) ->
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

  timestamp: generic name: "When.timestamp"

generic When.timestamp, Type.isObject, ( expires ) ->
  When.toISOString When.now().add expires

generic When.timestamp, Type.isString, Fn.identity


export { encode, decode, Nonce, Confidential, When }