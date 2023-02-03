import * as Fn from "@dashkite/joy/function"

clone = ( f ) ->
  Fn.arity (Math.max f.length, 1), ( first, args... ) ->
    first = structuredClone first
    Fn.apply f, [ first, args... ]

rclone = ( f ) ->
  Fn.arity (Math.max f.length, 1), ( args..., last ) ->
    last = structuredClone last
    Fn.apply f, [ args..., last ]
 
export { clone, rclone }