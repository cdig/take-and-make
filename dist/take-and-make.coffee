do ()->
  EVENTS = [
    "beforeunload"
    "click"
    "load"
    "unload"
  ]
  
  valuesByName = {}
  waitingTakers = []
  alreadyChecking = false
  
  
# Public
  
  window.Make = (name, value = name)->
    register(name, value) if name?
    
    # This is helpful for debugging — simply call Make() in the console to see what we've regstered
    return valuesByName
  
  
  window.Take = (needs, callback)->
    if needs?
      needs = [needs] if typeof needs is "string"
      
      taker =
        needs: needs
        callback: callback
      
      if allNeedsAreMet(needs)
        setTimeout ()-> # Preserve asynchrony
          notify(taker)
      else
        waitingTakers.push(taker)
    
    # This is helpful for debugging — simply call Take() in the console to see what we're waiting on
    return waitingTakers
  
  
  window.DebugTakeMake = ()->
    unresolved = {}
    for waiting in waitingTakers
      for need in waiting.needs
        unless valuesByName[need]?
          unresolved[need] ?= 0
          unresolved[need]++
    return unresolved

# Private
  
  register = (name, value)->
    throw new Error("You may not Make() the same name twice: #{name}") if valuesByName[name]?
    valuesByName[name] = value
    checkWaitingTakers()

  
  checkWaitingTakers = ()->
    return if alreadyChecking # Prevent recursive calls from Make()s inside notify()
    alreadyChecking = true
    
    for taker, index in waitingTakers # Depends on waitingTakers
      if allNeedsAreMet(taker.needs) # Depends on valuesByName
        waitingTakers.splice(index, 1) # Mutates waitingTakers
        notify(taker) # Calls to Make() or Take() will mutate valuesByName or waitingTakers
        alreadyChecking = false
        return checkWaitingTakers() # Restart: waitingTakers (and possibly valuesByName) were mutated
    
    alreadyChecking = false
  
  
  allNeedsAreMet = (needs)->
    return needs.every (name)-> valuesByName[name]?
  
  
  notify = (taker)->
    resolvedNeeds = (valuesByName[name] for name in taker.needs)
    taker.callback.apply(null, resolvedNeeds)
  
  
  # EVENT WRAPPERS #################################################################################
  
  makeHandler = (eventName)->
    return handler = (eventObject)->
      window.removeEventListener(eventName, handler)
      Make(eventName, eventObject)
      return undefined # prevent onunload from opening a popup
  
  
  for eventName in EVENTS
    window.addEventListener(eventName, makeHandler(eventName))
  
