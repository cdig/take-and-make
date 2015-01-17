# Take & Make

## Quick Start

Take & Make are included in [cdFoundation](https://github.com/cdig/cd-foundation). The two functions `Take()` and `Make()` are exposed as globals, so they should work anywhere. Make sure they're loaded before anything that uses them.

## Motivation

Somewhere in the dense thicket between module systems, dependency trees, injectors, resolvers, service discovery, and grossly abusing events because you don't have any of the former, you'll find **Take & Make**. They're wonderful, with only the slightest whiff of glue.

## Make

`Make(name:String, value:*)` **registers** a **value** for a **name**.
 
```coffee
Make("UniversalAnswer", 42)

Make "ScaryStory", (subject)->
  return "Once upon a time, #{subject} walked into the woods. #{subject} was eaten by a giant spider. The end. (OR IS IT?)"
```

The value can be of any type, and is optional. If you don't give a value, you're registering *the fact that something happened*. We call this a "one-time event".

```coffee
Make("Ready")
```

You may only register a name once — duplicates will error.

```coffee
Make("Five", 5)
Make("Five", "Five") # Throws an error
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

Lastly, out-of-the-box, we listen for a bunch of standard events on the `window`, and call Make() when they fire. That way, you can use Take() to wait for common events like the page being loaded, or the very first mouse click (possibly useful for WebAudioAPI, or debugging).

```coffee
Take "load", ()->
  alert("The page has finished loading. Aren't you glad I told you?")
```

The current events we wrap are:

* beforeunload
* click
* load
* unload

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

Also, **Take & Make** work asynchronously by design. That means *they donut work* with Angular 1.x's module/DI system (without gross workarounds). Here's the workaround I recommend: Don't use Angular. If you have to use Angular, then just.. maybe.. copy-paste stuff from whatever thing you want to Take into Angular modules. Serves you right for using Angular, *punk*. Alternatively, you can wrap whatever you're getting back from Take() in a promise. That'll play nice with Angular.


## Secrets for Powers Users

Having trouble getting a Take() to resolve? Getting lost in the dependency forest? We've got the debugging tool you need!

Open your browser console, and run `DebugTakeMake()`. It will return an object with all of the unresolved names as properties, and how many different Take() calls are waiting on them as values. Very, very helpful.

## License
Copyright (c) 2014-2015 CD Industrial Group Inc., released under MIT license.
