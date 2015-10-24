# Take & Make

## Quick Start

The two functions `Take()` and `Make()` are exposed as globals, so they should work anywhere. Make sure they're loaded before anything that uses them.

## Motivation

Somewhere in the dense thicket between module systems, dependency trees, injectors, resolvers, service discovery, and grossly abusing events because you don't have any of the former, you'll find **Take & Make**. They're wonderful, with only the slightest whiff of glue.

## Make

`Make(name:String, value:*)` **registers** a **value** for a **name**.
 
```coffee
Make("UniversalAnswer", 42)

Make "ScaryStory", (subject)->
  return "Once upon a time, #{subject} walked into the woods. #{subject} was eaten by a giant spider. The end. (OR IS IT?)"
```

The value can be of any type, and is optional. If you don't give a value, you're registering *the fact that something happened*. We call this a **one-time event**.

```coffee
Make("Ready")
```

You may only register a name once — duplicates will error.

```coffee
Make("Six", 6)
Make("Six", "VI") # Throws an error
```


## Take

`Take(names:Array, callback:Function)` gives you back values registered with `Make()`.
Once the requested names have all been registered, your callback function is called with the named values in order.

```coffee
Take ["ScaryStory", "UniversalAnswer"], (ScaryStory, UniversalAnswer)->
  console.log(UniversalAnswer) # Logs: 42
  console.log(ScaryStory(UniversalAnswer)) # Logs: Once upon a time, 42 walked into the woods. 42 was eaten by a giant spider. The end. (OR IS IT?)
```

Pro tip: if there's only one name, you can use a string instead of an array.
Oh, and if the name you're requesting is a *one-time event*,
then the value will just be the same as the name. It's idiomatic to place these names last in the array, and then just omit them from the function parameters.

```coffee

# "Ready" is a one-time event, so we can just omit it from the function arguments.
Take ["UniversalAnswer", "Ready"], (UniversalAnswer)->
  console.log("I'm #{UniversalAnswer} years old and I'm ready for action!") # Logs: "I'm 42 years old and I'm ready for action!"

# Only one name? Use a string instead of an array!
Take "Ready", ()->
  
  # You can name the callback arguments whatever you want. This gives nice "import as" behaviour.
  Take "TheFuture", (fuuuuture)->
    fuuuuture() # Logs: "We're living in the future!"
  
  # You can call Take() before calling Make()
  Make "TheFuture", ()->
    console.log("We're living in the future!")
```


## Standard One-Time Events

Out-of-the-box, we listen for a bunch of standard events on the `window`, and call Make() when they fire. That way, you can use Take() to wait for common events like the page being loaded, or the very first mouse click (possibly useful for WebAudioAPI, or debugging).

```coffee
Take "load", ()->
  alert("The page has finished loading. Aren't you glad I told you?")
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


## More examples, please!

Dance, monkey!

```coffee
Take ["MusicLibrary", "AudioEngine"], (MusicLibrary, AudioEngine)->
  
  Make "PlaybackControl", PlaybackControl =
    currentSong: 0
    next: ()-> skip(+1)
    prev: ()-> skip(-1)
  
  skip = (n)->
    PlaybackControl.currentSong += n
    song = MusicLibrary.getSong(PlaybackControl.currentSong)
    AudioEngine.playSong(song)
```

Dance! Dance!

```coffee
Take "load", ()->
  for elm in document.querySelectorAll("div")
    elm.textContent = "I'm a chaotic monkey!"
```

I love you, monkey.

```coffee
Take "Backend", (Backend)->
  disconnectPrevented = false
  
  Make "PreventDisconnect", ()->
    disconnectPrevented = true
  
  Take "unload", ()->
    unless disconnectPrevented
      Backend.disconnect()
```

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


## Secrets for Powers Users

### Debugging

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


### Angular

If we detect that you're using Angular, then calls to Make will automatically generate Angular injectables. To use these, you need to do 2 things.

First, make sure you add the `TakeAndMake` module to you Angular app.

```coffee
angular.module "MyApp", [
  'TakeAndMake'
]
```

Secondly, you need to manually bootstrap your app, but only after all the Make calls are done. If you do all your Make calls in the first tick of the event loop after `load`, then this should suffice:

```coffee
angular.element(document).ready ()->
  setTimeout ()->
    angular.bootstrap(document, ['MyApp'])
```

We can't really do anything smart to detect when all the Make calls will be done with, because that's up to your code. So, you'll just have to manually handle this part. But the benefit is totally worth it.

## Future Plans

Take & Make are a temporary solution.
They're deliberately very, very simple (~100 lines of code). They solve the 90% of the problem that must be solved, and they avoid the 10% that'd turn them into a huge heap of code and complication.
In the future, we'll need more advanced tools for code modularization and lazy loading and compilation and, most importantly, dead code elimination.
Take & Make give us enough to get by on until 2016, once ES6 modules become ubiquitous. They will do just fine for our needs until then, and we can avoid the clusterfuck of AMD, RequireJS, Webpack, CommonJS, NPM, JSPM, etc.

## License
Copyright (c) 2014-2015 CD Industrial Group Inc., released under MIT license.
