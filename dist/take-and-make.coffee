# Take & Make
# Just the right amount of dependency resolution service.
#
# Make(name:String, value:*) registers a value with a name.
# The value can be of any type, and is optional.
# If you don't give a value, you're registering *the fact something happened*.
# In that case, the value will just be the same as the name.
#
# Take(names:Array, callback:Function) does two things.
# First, it waits until Make() has been called for each of the names you request.
# Then, it gathers up the values for those names, and calls your callback with them.
# Pro tip: if there's only one name, you can use a string instead of an array.
#
# Lastly, out-of-the-box, we listen for a bunch of standard events, and call Make() when they fire.
# That way, you can use Take() to wait for common events like the page being loaded, or the very
# first mouse click (useful for WebAudioAPI).


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
	
	window.Make = (name, value)->
		if name?
			throw new Error("You may not Make() the same name twice: #{name}") if valuesByName[name]?
			valuesByName[name] = if value? then value else name
			checkWaitingTakers()
		
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
	
