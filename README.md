# Take & Make

*Just the right amount of dependency resolution service.™*

Somewhere in the dense thicket between module systems, dependency trees and injectors and resolvers, service discovery (whatever the heck that is), and grossly abusing events for load-time notification, you'll find this duo of tools. They're wonderful, with only the slightest whiff of glue.

`Make(name, value)` registers a named value (*clearly*). The name must be a string. The value can be of any type, and is optional. If you don't give a value, you're registering *the fact that something happened*. You may only register a name once — duplicates will error.

`Take(names, callback)` requests values that were (or will be) registered with Make. When those values have all been registered, your callback function is called with the values, in order. Pro tip: if there's only one name, you can just pass a string instead of an array. Oh, and if the name you're requesting doesn't have a value (because values are optional when calling Make, remember), then the value will just be the same as the name. It's idiomatic to place these *event-like* names last, and just omit them from the function parameters.

Lastly, out-of-the-box, we listen for a bunch of standard events, and call Make() when they fire. That way, you can use Take() to wait for common events like the page being loaded, or the very first mouse click (possibly useful for WebAudioAPI, or debugging). The current events we wrap are `beforeunload`, `click`, `load`, `unload`.

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

Now, don't you dare create any circular dependencies. I haven't read those papers, so sod off.

Also, **Take & Make** work asynchronously by design. That means they don not work with Angular 1.x's module/DI system (without gross workarounds). Here's the workaround I recommend: Don't use Angular. If you have to use Angular, then just.. maybe.. copy-paste stuff from whatever thing you want to Take into Angular modules. Serves you right for using Angular, *punk*.


## License
Copyright (c) 2014-2015 CD Industrial Group Inc., released under MIT license.
