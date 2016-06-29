# Since this is typically the first bit of code included in our big compiled and
# concatenated JS files, this is a great place to demand strictness. CoffeeScript
# does not add strict on its own, but it will permit and enforce it.
"use strict";

# Bail if Take&Make is already running in this scope, or if something else is using our names
return if Take? or Make?

# We declare our globals such that they're visible everywhere within the current scope.
# This allows for namespacing — all things within a given scope share a copy of Take & Make.
Take = null
Make = null
DebugTakeMake = null

do ()->
  
  made = {}
  waitingTakers = []
  alreadyChecking = false
  clone = (o)-> if Object.assign? then Object.assign({}, o) else o

  
# Public
  
  Make = (name, value = name)->
    # Debug — call Make() in the console to see what we've regstered
    if not name?
      return clone made
    
    # Synchronous register, returns value
    else
      return register name, value
  
  
  Take = (needs, callback)->
    # Debug — call Take() in the console to see what we're waiting for
    if not needs?
      return waitingTakers.slice()
    
    # Synchronous and asynchronous resolve, returns value or object of values
    else
      resolve needs, callback
  
  
  DebugTakeMake = ()->
    unresolved = {}
    for waiting in waitingTakers
      for need in waiting.needs
        unless made[need]?
          unresolved[need] ?= 0
          unresolved[need]++
    return unresolved


# Private
  
  register = (name, value)->
    throw new Error("You may not Make(\"\") an empty string.") if name is ""
    throw new Error("You may not Make() the same name twice: #{name}") if made[name]?
    made[name] = value
    checkWaitingTakers()
    value

  
  checkWaitingTakers = ()->
    return if alreadyChecking # Prevent recursion from Make() calls inside notify()
    alreadyChecking = true
    
    # Comments below are to help reason through the (potentially) recursive behaviour
    
    for taker, index in waitingTakers # Depends on `waitingTakers`
      if allNeedsAreMet(taker.needs) # Depends on `made`
        waitingTakers.splice(index, 1) # Mutates `waitingTakers`
        notify(taker) # Calls to Make() or Take() will mutate `made` or `waitingTakers`
        alreadyChecking = false
        return checkWaitingTakers() # Restart: `waitingTakers` (and possibly `made`) were mutated
    
    alreadyChecking = false
  
  
  allNeedsAreMet = (needs)->
    return needs.every (name)-> made[name]?
  
  
  notify = (taker)->
    resolvedNeeds = (made[name] for name in taker.needs)
    taker.callback.apply(null, resolvedNeeds)
  
  
  resolve = (needs, callback)->
    # We always try to resolve both synchronously and asynchronously
    asynchronousResolve needs, callback if callback?
    synchronousResolve needs
  
  
  asynchronousResolve = (needs, callback)->
    if needs is ""
      needs = []
    else if typeof needs is "string"
      needs = [needs]
    
    taker = needs: needs, callback: callback
    
    if allNeedsAreMet needs
      # Preserve asynchrony
      setTimeout ()-> notify taker
    else
      waitingTakers.push taker
  
  
  synchronousResolve = (needs)->
    if typeof needs is "string"
      return made[needs]
    else
      o = {}
      o[n] = made[n] for n in needs
      return o

  
  # EVENT WRAPPERS #################################################################################
  
  addListener = (eventName)->
    window.addEventListener eventName, handler = (eventObject)->
      window.removeEventListener eventName, handler
      Make eventName, eventObject
      return undefined # prevent unload from opening a popup
  
  addListener "beforeunload"
  addListener "click"
  addListener "unload"
  
  switch document.readyState
    when "loading"
      addListener "DOMContentLoaded"
      addListener "load"
    when "interactive"
      Make "DOMContentLoaded"
      addListener "load"
    when "complete"
      Make "DOMContentLoaded"
      Make "load"
    else
      throw new Error "Unknown document.readyState: #{document.readyState}. Cannot setup Take&Make."
