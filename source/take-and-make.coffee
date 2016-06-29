do ()->
  made = {}
  waitingTakers = []
  alreadyChecking = false
  
  
# Public
  
  window.Make = (name, value = name)->
    register(name, value) if name?
    
    # This is helpful for debugging — simply call Make() in the console to see what we've regstered
    return made
  
  
  window.Take = (needs, callback)->
    resolve(needs, callback) if needs?
    
    # This is helpful for debugging — simply call Take() in the console to see what we're waiting on
    return waitingTakers
  
  
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
    needs = [needs] if typeof needs is "string"
    
    taker =
      needs: needs
      callback: callback
    
    if allNeedsAreMet(needs)
      setTimeout ()-> # Preserve asynchrony
        notify(taker)
    else
      waitingTakers.push(taker)
  
  
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
