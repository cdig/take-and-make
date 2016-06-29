do ()->
  
  # Bail if Take&Make is already running, or if something else is using our names
  return if window.Take? or window.Make?
  
  made = {}
  waitingTakers = []
  alreadyChecking = false
  clone = (o)-> if Object.assign? then Object.assign({}, o) else o

  
# Public
  
  window.Make = (name, value = name)->
    # Debug — call Make() in the console to see what we've regstered
    if not name?
      return clone made
    
    # Synchronous register, returns value
    else
      return register name, value
  
  
  window.Take = (needs, callback)->
    # Debug — call Take() in the console to see what we're waiting for
    if not needs?
      return waitingTakers.slice()
    
    # Synchronous and asynchronous resolve, returns value or object of values
    else
      resolve needs, callback
  
  
  window.DebugTakeMake = ()->
    unresolved = {}
    for waiting in waitingTakers
      for need in waiting.needs
        unless made[need]?
          unresolved[need] ?= 0
          unresolved[need]++
    return unresolved


# Private
  
  register = (name, value)->
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
    isStr = typeof needs is "string"
    
    # Asynchronous resolve
    if callback?
      _needs = if isStr then [needs] else needs
      
      taker =
        needs: _needs
        callback: callback
      
      if allNeedsAreMet _needs
        setTimeout ()-> # Preserve asynchrony
          notify(taker)
      
      else
        waitingTakers.push(taker)
    
    # Synchronous string resolve - return the matching need value or undefined
    return made[needs] if isStr
    
    # Synchronous array resolve - return an object mapping need names to made values or undefinds
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
