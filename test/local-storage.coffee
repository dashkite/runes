store = {}

LocalStorage =

  getItem: (key) -> store[key]

  setItem: (key, value) -> store[key] = value

  clear: -> store = {}

  _data: store


global.window = localStorage: LocalStorage
globalThis.localStorage = LocalStorage