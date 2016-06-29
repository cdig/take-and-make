# Take & Make
Somewhere in the dense thicket between module systems, dependency trees, injectors, resolvers, service discovery, and grossly abusing events because you don't have any of the former, you'll find **Take & Make**. They're wonderful, with only the slightest whiff of glue.


## Quick Start
`Take()` and `Make()` are bare globals. Make sure this code is loaded before anything that uses them.


## Changes In v3
* Primitive support for namespacing
* Take & Make now return helpful stuff in all use cases
* Allow `Take ""` to work the same as `Take []`
* Take & Make are no longer declared on the window
* `"use strict";` at the top, on behalf of all code that follows
* Debug outputs are cloned, to avoid mutation pains
* Removed Angular support


## Make
`Make(name:String, value:*)` **registers** a **value** for a **name**.
 
```coffee
Make UniversalAnswer", 42

Make "ScaryStory", (subject)->
  return "Once upon a time, #{subject} walked into the woods. #{subject} was eaten by a giant spider. The end. (OR IS IT?)"
```

The value can be of any type, and is optional. If you don't give a value, you're registering *the fact that something happened*. We call this a **one-time event**.

```coffee
Make "Ready"
```

You may only register a name once — duplicates will error.

```coffee
Make "Six", 6
Make "Six", "VI" # Throws an error
```

Make will return the value you provide, for convenience.

```coffee
console.log Make "Weird Times With JavaScript", {1}[1] # What does this even....?
```


## Take
`Take(names:Array, callback:Function)` gives you back values registered with `Make()`.
Once the requested names have all been registered, your callback function is called with the named values as arguments.

```coffee
Take ["ScaryStory", "UniversalAnswer"], (ScaryStory, UniversalAnswer)->
  console.log UniversalAnswer # Logs: 42
  console.log ScaryStory UniversalAnswer # Logs: Once upon a time, 42 walked into the woods. 42 was eaten by a giant spider. The end. (OR IS IT?)
```

Pro tip: if there's only one name, you can use a string instead of an array.
Oh, and if the name you're requesting is a *one-time event*,
then the value will just be the same as the name. It's idiomatic to place these names last in the array, and then just omit them from the function parameters.

```coffee
# "Ready" is a one-time event, so we can just omit it from the function arguments.
Take ["UniversalAnswer", "Ready"], (UniversalAnswer)->
  console.log "I'm #{UniversalAnswer} years old and I'm ready for action!" # Logs: "I'm 42 years old and I'm ready for action!"

# Only one name? Use a string instead of an array!
Take "Ready", ()->
  
  # You can name the callback arguments whatever you want. This gives nice "import as" behaviour.
  Take "TheFuture", (fuuuuture)-> fuuuuture() # Logs: "We're living in the future!"
  
  # You can call Take() before calling Make()
  Make "TheFuture", ()-> console.log "We're living in the future!"
  
# Want a placeholder? You got it!
Take [], ()-> console.log "This code runs on the next turn of the event loop".
Take "", ()-> console.log "This is exactly the same as the above."
```


## Standard One-Time Events
Out-of-the-box, we listen for a bunch of standard events on the `window`, and call Make() when they fire for the first time. That way, you can use Take() to wait for common events like the page being loaded, or the very first mouse click (possibly useful for WebAudioAPI, or debugging).

```coffee
Take "load", ()->
  alert "The page has finished loading. Aren't you glad I told you?"
```

The current events we wrap are:

* beforeunload
* click
* DOMContentLoaded
* load
* unload

The value associated with these events is the event object (whenever possible — sometimes, load and DOMContentLoaded will not have the event). So, if you want the event info for the first click, that's available!

```coffee
Take "click", (click)->
  alert("The page was clicked at #{click.clientX}, #{click.clientY}")
```


## Sync or Async?

Make is synchronous. Take can be used synchronously or asynchronously. When you give Take a callback, that callback is never called synchronously, even if all of the values it requests on have already been registered.

```coffee
# Asynchronous Take, before Make — doesn't log yet
Take "Me", (Me)-> console.log "Late"

# Synchronous Take, before Make — immediately logs undefined
console.log Take "Me"

# Mixed Take, before Make — immediately logs undefined, callback doesn't run yet
console.log Take "Me", (Me)-> console.log "Later"

# Synchronous Make — immediately causes our two Take callbacks above to log "Late" and "Later", in that order
Make "Me", "Happy"

# Asynchronous Take, after Make — to preserve asynchrony, waits until the next turn of the event loop then logs "Super Late"
Take "Me", (Me)-> console.log "Super Late"

# Synchronous Take, after Make — immediately logs "Happy"
console.log Take "Me"

# Mixed Take, after Make — immediately logs "Happy", waits until the next tick, then logs "Finally"
console.log Take "Me", (Me)-> console.log "Finally"
```

When you call Make, it _might_ immediately trigger some faraway Take to be resolved. In that case, the Take callback will run _before_ the code immediately following your Make. Thus, if you need to do any initialization before your Make'd thing is ready-to-go, then for goodness sakes do that stuff before you call Make.

```coffee
Take "Sys", (Sys)-> Sys()
Take "Sys", (Sys)-> Sys.tem()

Sys = ()-> console.log "Sys call"

# If we called Make("Sys", Sys) now,
# our first Take callback would log "Sys call"
# and our second Take callback would error because Sys.tem is undefined,
# because Make() is synchronous and immediately runs all matching Takes.

Sys.tem = ()-> console.log "tem call"

Make "Sys", Sys
# synchronously logs "Sys call"
# synchronously logs "tem call"
```

When you use Take synchronously, you can also specify multiple needs.
In that case, the return value will be an object mapping the needed names to their values.
Any values that haven't yet been registered will be `undefined`.

```coffee
Make "A"
Make "B", 2

result = Take ["A", "B", "C"]

console.log result.A # "A"
console.log result.B # 2
console.log result.C # undefined
```


## Debugging
Having trouble getting a Take() to resolve?
Getting lost in the dependency forest?
We've got the debugging tool you need!

Open your browser console, and run `DebugTakeMake()`.
It will return an object with all of the unresolved names as properties,
and how many different Take() calls are waiting on them as values.
Very, very helpful.

In the console, you can also just call `Make()` to see the list of all registered values,
or `Take()` to see the list of all requested values that haven't been resolved.
But `DebugTakeMake()` is a bit nicer to look at than `Take()`,
so you're probably better off just sticking with that.


## Words Of Warning
Don't you dare create any circular dependencies. I haven't read those papers, so sod off.

```coffee
# Don't do this:

Take "A", (A)->
  Make "B", ()->
    console.log("Derp")

Take "B", (B)->
  Make "A", ()->
    console.log("Herp")

# If you do this, Take("A") and Take("B") will never resolve.
```


## Future Plans
Take & Make are a temporary solution.
They solve the 95% of the problem that must be solved, and they avoid the 5% that'd turn them into a huge heap of code and complication.
In the future, we'll need more advanced tools for code modularization and lazy loading and compilation and, most importantly, dead code elimination.
Take & Make give us enough to get by on until 2017, once ES6 modules become ubiquitous. They will do just fine for our needs until then, and we can avoid the clusterfuck of AMD, RequireJS, Webpack, CommonJS, NPM, JSPM, etc.


## License
Copyright (c) 2014-2016 CD Industrial Group Inc., released under MIT license.
