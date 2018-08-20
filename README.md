# Take & Make
Somewhere in the dense thicket of module systems, dependency graphs, injectors, registries, service discovery, and grossly abusing events because you don't like any of the former, you'll find **Take & Make**. They're wonderful, with only the slightest whiff of glue.


## Quick Start
`Take` and `Make` are bare globals. Be sure that `take-and-make.js` is loaded before anything that uses them.


## Make
`Make` **registers** a **value** for a **name**.

```coffee
Make "UniversalAnswer", 42

Make "ScaryStory", (subject)->
  "Once upon a time, #{subject} walked into the woods. #{subject} was eaten by a giant spider. The end."
```

The value can be of any type, and is optional. If you don't provide a value, you're registering *the fact that something has happened*. We call this a **one-time event**.

```coffee
Make "Ready"
```

You may only register a name once — duplicates will error.

```coffee
Make "Six", 6
Make "Six", "VI" # Throws an error
```

The name can be any valid string. Also, `Make` will return the value you provide, for convenience.

```coffee
six = Make "Six", 1 + 2 + 3
console.log six # 6
```


## Take
`Take` gives you back values registered with `Make`.

Give `Take` one or more names, and a callback function with an argument for each name.

```coffee
Take "Six", (Six)->
  console.log Six # 6
```

Once the requested names have all been registered, your callback function is called with the named values as arguments.

```coffee
Take ["ScaryStory", "UniversalAnswer"], (ScaryStory, UniversalAnswer)->
  console.log ScaryStory UniversalAnswer # Once upon a time, 42 walked into the woods. 42 was eaten by a giant spider. The end.
```

This writing-the-names-twice redundancy might seem annoying, but it gives you a handful of niceties:
* Your names don't have to be valid JS identifiers, and you can use a different name locally than globally.
    ```coffee
    Take ["🤯","Super Cool School"], (ExplodingHead, School)->
    ```
* You can use destructuring on the function args.
    ```coffee
    Take "Position", ({x:x, y:y})->
    ```
* Your code will survive minification with aplomb.
    ```js
    Take("q",function(Six){console.log(Six)});)
    ```

If the name you're requesting is a *one-time event*, then the value will just be the same as the name.
It's idiomatic to place these names last in the array, and then just omit them from the function parameters.

```coffee
# "Ready" is a one-time event, so we can just omit it from the function arguments.
Take ["UniversalAnswer", "Ready"], (UniversalAnswer)->
  console.log "I'm #{UniversalAnswer - 33} years old and I'm ready for action!" # "I'm 9 years old and I'm ready for action!"

# It's common to use one-time events like this:
Take "Ready", ()->

  # Of course, you can call Take() before calling Make()
  Take "In The Future", (theFutureIsNow)-> theFutureIsNow() # "We're living in the future!"
  Make "In The Future", ()-> console.log "We're living in the future!"

# It's also common to do this:
Take [], ()-> console.log "This code runs on the next turn of the event loop".
Take "", ()-> console.log "This is exactly the same as the above."
```


## Standard One-Time Events
Out-of-the-box, we listen for a bunch of standard events on the `window`, and call `Make` when they fire for the first time. That way, you can use `Take` to wait for common events like the page being loaded, or the very first mouse click (useful for WebAudioAPI, or debugging).

```coffee
Take "load", ()->
  alert "The page has finished loading. Aren't you glad I told you?"
```

The current events we offer are:

* beforeunload
* click
* DOMContentLoaded
* load
* unload

The value associated with these events is the event object (whenever possible — sometimes, load and DOMContentLoaded will not have the event). So, if you want the event info for the first click, that's available!

```coffee
Take "click", (click)->
  alert "The page was clicked at #{click.clientX}, #{click.clientY}"
```


## Sync or Async?
`Make` is synchronous. `Take` can be used synchronously or asynchronously. When you give `Take` a callback, that callback is *always* called asynchronously, even if all of the values it requests on have already been registered. `Take` callbacks are run in the order they're received.

```coffee
# Asynchronous Take, before Make — doesn't log yet
Take "Me", (Me)-> console.log "Late"

# Synchronous Take, before Make — immediately logs undefined
console.log Take "Me"

# Mixed Take, before Make — immediately logs undefined, callback doesn't run yet
console.log Take "Me", (Me)-> console.log "Later"

# Synchronous Make — immediately causes our two Take callbacks above to log "Late" and "Later", in that order
Make "Me", "Happy"

# Asynchronous Take, after Make — to preserve asynchrony, waits until the next turn of the event loop then logs "Super Late"
Take "Me", (Me)-> console.log "Super Late"

# Synchronous Take, after Make — immediately logs "Happy"
console.log Take "Me"

# Mixed Take, after Make — immediately logs "Happy", waits until the next tick, then logs "Finally"
console.log Take "Me", (Me)-> console.log "Finally"
```

When you call `Make`, it _might_ immediately trigger some faraway `Take` to be resolved. In that case, the `Take` callback will run _before_ the code immediately following your `Make`. Thus, if you need to do any initialization before your `Make`'d thing is ready-to-go, then for goodness sakes do that stuff before you call `Make`.

```coffee
Take "Sys", (Sys)-> Sys()
Take "Sys", (Sys)-> Sys.tem()

Sys = ()-> console.log "Sys call"

# Make is synchronous.
# So if we called Make("Sys", Sys) now,
# our first Take callback would log "Sys call"
# and our second Take callback would error because Sys.tem is undefined.

Sys.tem = ()-> console.log "tem call"

Make "Sys", Sys
# synchronously logs "Sys call"
# synchronously logs "tem call"
```

When you use `Take` synchronously, you can also specify multiple names.
In that case, the return value will be an object mapping the names to their values.
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
Having trouble getting a `Take` to resolve?
Getting lost in the dependency forest?
We've got the debugging tool you need!

Open your browser console, and run `DebugTakeMake()`.
It will return an object with all of the unresolved names as properties,
and how many different `Take` calls are waiting on them as values.
Very, very helpful.

In the console, you can also just call `Make()` to see the list of all registered values,
or `Take()` to see the list of all requested values that haven't been resolved.
But `DebugTakeMake()` is a bit nicer to look at than `Take()`,
so you're probably better off just sticking with that.


## Words Of Warning
Don't you dare create any circular dependencies.

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

## Building
To compile from source...
```bash
coffee --bare -o dist/take-and-make.js -c source/take-and-make.coffee
```

## License
Copyright (c) 2014-2018 CD Industrial Group Inc., released under MIT license.
