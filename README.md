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
seven = Make "6+1", 6 + 1
console.log seven # 7
```


## Take
`Take` gives you back values registered with `Make`.

Give `Take` one or more names, and a callback function with an argument for each name.

```coffee
Take "Six", (Six)->
  console.log Six # 6

Take ["ScaryStory", "UniversalAnswer"], (ScaryStory, UniversalAnswer)->
  console.log ScaryStory UniversalAnswer # Once upon a time, 42 walked into the woods. 42 was eaten by a giant spider. The end.
```

This writing-the-names-twice redundancy might seem annoying, but it gives you a handful of niceties:
* Your names don't have to be valid JS identifiers, and you can use a different name locally than globally.
    ```coffee
    Take ["🤯", "Super Cool School"], (ExplodingHead, School)->
    ```
* You can use destructuring on the function args.
    ```coffee
    Take "Position", ({x:x, y:y})->
    ```
* Your code will survive minification with aplomb.
    ```js
    Take("Six",function(q){console.log(q)});
    ```

If the name you're requesting is a *one-time event*, then the value will just be the same as the name.
It's idiomatic to place these names last in the array, and then just omit them from the function signature.

```coffee
# "Ready" is a one-time event, so we can just omit it from the function.
Take ["UniversalAnswer", "Ready"], (UniversalAnswer)->
  console.log "I'm #{UniversalAnswer - 33} years old and I'm ready for action!" # "I'm 9 years old and I'm ready for action!"

# It's common to use one-time events for simple coordination, like this:
Take "Ready", ()->
  # We're ready in here.

# Of course, you can call Take before calling Make
Take "In The Future", (theFutureIsNow)->
  theFutureIsNow()

# As soon as this Make finishes, the above Take "In The Future" callback will run.
Make "In The Future", ()->
  console.log "We're living in the future!"
```

You can also just call `Take` without asking for anything. This gives you two niceties:
1. It creates a new private namespace inside the callback, like an IIFE.
2. It runs the callback [at the end of the current task](https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API/Microtask_guide), which means anything else declared in the outer scope should be parsed and ready to go, even if it's a forward reference.

```
Take [], ()-> console.log "This code runs later, but soon — in a microtask".
Take "", ()-> console.log "This is exactly the same as the above."
```

It's overwhelmingly common to use `Take [], ()->` at the very top of a file, and nest everything inside it. You get the above benefits, plus it's easy to add dependencies if you need them. Throw a `Make "Name", API` at the bottom of the file (where the API is a function or object), and you have a super nice pattern for creating tidy modules / micro-libraries / components / systems / classes / bags-of-functions.

This pattern is what makes Take & Make sing. It lets you organize your CoffeeScript into small files, each with a clear sense of purpose. At compile time, you have the freedom to decide whether and how the files should be concatenated. There's no extra preprocessing needed, so compile times are instant. You can load the resulting code in any order — even lazily — and everything just works. And because of the use of microtasks (and some of the async behaviour described below), the initial execution of the code is super fast — there's effectively zero overhead, but you get the joy of forward references / lazy loading / one-time events / micro-libraries / etc.

## Standard One-Time Events
Out-of-the-box, we listen for a bunch of standard events on the `window`, and call `Make` when they fire for the first time. That way, you can use `Take` to wait for common events like DOMContentLoaded, or the very first mouse click (useful for WebAudioAPI, or debugging).

```coffee
Take "DOMContentLoaded", ()->
  alert "The html has finished loading and it's safe to manipulate. Aren't you glad I told you?"
```

The current events we offer are:

* DOMContentLoaded
* load
* click
* beforeunload
* unload

The value associated with these events is the event object (whenever possible — sometimes, load and DOMContentLoaded will not have the event). So, if you want the event info for the first click, that's available!

```coffee
Take "click", (click)->
  alert "The page was clicked at #{click.clientX}, #{click.clientY}"
```


## Sync or Async?
This gets a bit complicated. In practice, you can just use Take and Make as shown above, and things will just work beautifully. Internally, Take and Make do some careful balancing of asynchronous behaviour to make forward references work dependably, but without generating excessive microtasks. The below examples are intended mostly for the sake of comprehensiveness. You don't need to be conscious of this stuff in practice.

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

# Asynchronous Take, after Make — to preserve asynchrony, waits using queueMicrotask, then logs "Super Late"
Take "Me", (Me)-> console.log "Super Late"

# Synchronous Take, after Make — immediately logs "Happy"
console.log Take "Me"

# Mixed Take, after Make — immediately logs "Happy", waits using queueMicrotask, then logs "Finally"
console.log Take "Me", (Me)-> console.log "Finally"
```

When you call `Make`, it _might_ immediately trigger some faraway `Take` to be resolved. In that case, the `Take` callback will run _before_ the code immediately following your `Make`. Thus, if you need to do any initialization before your `Make`'d thing is ready-to-go, then for goodness sakes do that stuff before you call `Make`. (Though [see below](#modern-async) for another option.)

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


## Modern Async

There's a special version of Take that returns a promise, useful for async/await.
Like the synchronous version of Take, it'll resolve the promise with either a single value or an object of values.

```coffee
A = await Take.async "A"
{B, C} = await Take.async ["B", "C"]
```

Remember when we said Make was synchronous? Yeah, that was a lie. There's also an async version.
This will defer committing the value (and resolving Takes) until the end of the current task.

```coffee
Make.async "Wait For It", "Patience, my young apprentice"
console.log Take "Wait For It" # undefined, because Make.async doesn't commit until later

# Compare with:
Make "It Is Time", "NOW"
console.log Take "It Is Time" # "NOW", because Make synchronously committed the value
```

This async version of Make is particularly nice for building an API that is a function, with some additional functions or data attached to it:

```coffee
Make.async "MultiTool", MultiTool = (k, v)->
  # Do some stuff

MultiTool.alt = (k, v)->
  # Different stuff
```

The above example would be unsafe if you just used `Make` instead of `Make.async`, because immediately after running Make, before `alt` is created, any `Take` that was just waiting for `MultiTool` would run.


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


## Advice
Don't you dare create any circular dependencies.

```coffee
# Don't do this:

Take "A", (A)->
  Make "B", ()->
    # Do something with A

Take "B", (B)->
  Make "A", ()->
    # Do something with B

# If you do this, Take("A") and Take("B") will never resolve.
```

As an alternative, you can make cunning use of `Take.async`.

```coffee
Take "A", (A)->
  Make "B", ()->
    # Do something with A

Take [], ()->
  Make "A", ()->
    B = await Take.async "B"
    # Do something with B
```

`Take.async` is also handy when you have a bit of code that only needs to add a dependency in certain circumstances.

```coffee
Take ["CommonLib"], (CommonLib)->

  # Do common stuff

  FlavourLib = await Take.async if someLikeItHot then "Spicy" else "Mild"

  # Do some common stuff... with flavour!

```

You could do the above using synchronous `Take` instead of `Take.async`, but then you risk errors if the things you're taking don't exist yet.


## Building
```bash
yarn build
```

## Example
Take & Make are used to manage the module dependencies and load-time behaviour for all CDIG JavaScript/CoffeeScript projects. For example, have a look at the main entry point for [SVGA](https://github.com/cdig/svga/blob/v4-1/source/core/main.coffee). They've been run tens (maybe hundreds by now) of millions of times in production.
