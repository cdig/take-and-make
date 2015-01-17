# Take & Make

Somewhere in the dense thicket between module systems, dependency trees and injectors and resolvers, service discovery (whatever the heck that is), and grossly abusing events for load-time notification, you'll find this duo of tools. They're wonderful, with only the slightest whiff of glue.

## Make

`Make(name:String, value:*)` registers a value for a name.
 
```coffee
Make("UniversalAnswer", 42)

Make "ScaryStory", (subject)->
  return "Once upon a time, #{subject} walked into the woods. #{subject} was eaten by a giant spider. The end. (OR IS IT?)"
```

The value can be of any type, and is optional. If you don't give a value, you're registering *the fact something happened*.

```coffee
Make("Ready")
```

You may only register a name once — duplicates will error.

```coffee
Make("Five", 5)
Make("Five", "Five") # Throws an error
```

## Take

`Take(names:*, callback:Function)` is what you use to get back values that were registered with Make.
When you call `Take()`, it waits until `Make()` has been called for each of the names you request.
Once those values have all been registered, your callback function is called with the values, in order.

```coffee
Take ["ScaryStory", "UniversalAnswer"], (ScaryStory, UniversalAnswer)->
  console.log(UniversalAnswer) # Logs: 42
  console.log(ScaryStory(UniversalAnswer)) # Logs: Once upon a time, 42 walked into the woods. 42 was eaten by a giant spider. The end. (OR IS IT?)
```

Pro tip: if there's only one name, you can use a string instead of an array.
Oh, and if the name you're requesting doesn't have a value (because values are optional when calling Make, remember),
then the value will just be the same as the name. It's idiomatic to place these *event-like* names last, and just omit them from the function parameters.


```coffee
Take "Ready", ()->
  
  # You can call Take() before calling Make(). You can also name the callback arguments whatever you want.
  Take "TheFuture", (tehFuture)->
    tehFuture()
  
  Make "TheFuture", ()->
    console.log("We're living in the future!")
```

Lastly, out-of-the-box, we listen for a bunch of standard events, and call Make() when they fire. That way, you can use Take() to wait for common events like the page being loaded, or the very first mouse click (possibly useful for WebAudioAPI, or debugging). The current events we wrap are `beforeunload`, `click`, `load`, `unload`.


```coffee
Take "load", ()->
  alert("The page has finished loading. Aren't you glad I told you?")
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

Also, **Take & Make** work asynchronously by design. That means they don not work with Angular 1.x's module/DI system (without gross workarounds). Here's the workaround I recommend: Don't use Angular. If you have to use Angular, then just.. maybe.. copy-paste stuff from whatever thing you want to Take into Angular modules. Serves you right for using Angular, *punk*. Alternatively, you can wrap whatever you're getting back from Take() in a promise. That'll play nice with Angular.


## License
Copyright (c) 2014-2015 CD Industrial Group Inc., released under MIT license.
