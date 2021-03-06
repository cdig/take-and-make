# Since this is typically the first bit of code included in our big compiled and
# concatenated JS files, this is a great place to demand strictness. CoffeeScript
# does not add strict on its own, but it will permit and enforce it.
"use strict";

# Bail if Take&Make is already running in this scope, or if something else is using our names
unless Take? or Make?

  # We declare our globals such that they're visible everywhere within the current scope.
  # This allows for namespacing — all things within a given scope share a copy of Take & Make.
  Take = null
  Make = null
  DebugTakeMake = null

  do ()->

    made = {}
    waitingTakers = []
    takersToNotify = []
    alreadyWaitingToNotify = false
    alreadyChecking = false
    microtasksNeeded = 0
    microtasksUsed = 0

    Make = (name, value = name)->
      # Debug — call Make() in the console to see what we've regstered
      return clone made if not name?

      # Synchronous register, returns value
      register name, value


    Take = (needs, callback)->
      # Debug — call Take() in the console to see what we're waiting for
      return waitingTakers.slice() if not needs?

      # Synchronous and asynchronous resolve, returns value or object of values
      resolve needs, callback


    # A variation of Make that defers committing the value
    Make.async = (name, value = name)->
      queueMicrotask ()->
        Make name, value


    # A variation of Take that returns a promise
    Take.async = (needs)->
      new Promise (res)->
        Take needs, ()->
          # Resolve the promise with a value or object of values
          res synchronousResolve needs


    DebugTakeMake = ()->
      output =
        microtasksNeeded: microtasksNeeded
        microtasksUsed: microtasksUsed
        unresolved: {}
      for waiting in waitingTakers
        for need in waiting.needs
          unless made[need]?
            output.unresolved[need] ?= 0
            output.unresolved[need]++
      return output


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
        takersToNotify.push taker
        microtasksNeeded++
        unless alreadyWaitingToNotify
          alreadyWaitingToNotify = true
          queueMicrotask notifyTakers # Preserve asynchrony
          microtasksUsed++
      else
        waitingTakers.push taker


    synchronousResolve = (needs)->
      if typeof needs is "string"
        return made[needs]
      else
        o = {}
        o[n] = made[n] for n in needs
        return o


    notifyTakers = ()->
      alreadyWaitingToNotify = false
      takers = takersToNotify
      takersToNotify = []
      notify taker for taker in takers
      null


    notify = (taker)->
      resolvedNeeds = taker.needs.map (name)-> made[name]
      taker.callback.apply(null, resolvedNeeds)


    # IE11 doesn't support Object.assign({}, obj), so we just use our own
    clone = (obj)->
      out = {}
      out[k] = v for k,v of obj
      out


    # We want to add a few handy one-time events.
    # However, we don't know if we'll be running in a browser, or in node.
    # Thus, we look for the presence of a "window" object as our clue.
    if window?

      addListener = (eventName)->
        window.addEventListener eventName, handler = (eventObject)->
          window.removeEventListener eventName, handler
          Make eventName, eventObject
          return undefined # prevent unload from opening a popup

      addListener "beforeunload"
      addListener "click"
      addListener "unload"

      # Since we have a window object, it's probably safe to assume we have a document object
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


    # Finally, we're ready to hand over control to module systems
    if module?
      module.exports = {
        Take: Take,
        Make: Make,
        DebugTakeMake: DebugTakeMake
      }
