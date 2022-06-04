import { confidential } from "panda-confidential"

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

export { JSON36, Confidential }