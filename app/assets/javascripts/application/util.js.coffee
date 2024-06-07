# Code for defining namespaces in coffee script
namespace = (target, name, block) ->
  [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
  top    = target
  target = target[item] or= {} for item in name.split '.'
  block target, top

(exports ? @).namespace = namespace #make it globally available


window.setItemWithExpiry = (key, value, expiryDuration = 1) ->
  now = new Date().getTime()
  expirationTime = now + expiryDuration
  localStorage.setItem key, JSON.stringify({ value: value, expiry: expirationTime })
  

window.getItemWithExpiry = (key) ->
  # localStorage.removeItem key
  dataStr = localStorage.getItem key
  return null unless dataStr
  data = JSON.parse dataStr
  if data.expiry < new Date().getTime()
    localStorage.removeItem key
    return null
  else
    return data.value