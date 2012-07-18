backbone.soundmanager2
======================

`Backbone.SoundManager2` is a wrapper around [SoundManager2](http://www.schillmania.com/projects/soundmanager2/)
that helps including and using it within a [Backbone](http://backbonejs.org/) application.

How to use?
-----------

You should first initialize a single `Backbone.SoundManager2` player object, for instance as a global `App.player`:

    App.player = new Backbone.SoundManager2
    
The player expects to be given `playable` objects, that is `Backbone.Model` objects, extended with a `getAudioURL`
asynchronous method to return a URL to be played.

```
App.player.load playable    # Play a playable model
App.player.toggle()         # Toggle play/pause
App.player.stop()           # You got this one, right? :-)
App.player.setPosition 0.25 # Set playing position to 25%
App.player.setVolume   0.75 # Set volume to 75%
```

Please, refer to the code for more details about the available functions. Each of them are properly
documented.

How to integrate?
-----------------

A `Backbone.SoundManager2` instance will emit events related to its actions. Those events are also
emitted on any playable model current being played. 

You can use those to integrate the player within you `Backbone.View`. For instance, for a global
player view:

```
class App.View.Player extends Backbone.View
  initialize: ->
    App.player.bind "released", @clear
    App.player.bind "loaded",   @loaded
    App.player.bind "loading",  @loading
    App.player.bind "paused",   @paused
    App.player.bind "played",   @played
    App.player.bind "playing",  @updatePosition
    App.player.bind "resumed",  @played
    App.player.bind "stopped",  @stopped
    App.player.bind "finished", @finished

  updatePosition: (sound) =>
    return unless sound?

    @$(".bar .filler").css "width",
      "#{Math.round(100 * sound.position / sound.durationEstimate)}%"

    position = new Date sound.position

    # Duration is an estimate so we're better
    # computing it each time..

    duration = new Date sound.durationEstimate

    @$(".played").text _.sprintf("%d:%02d", position.getMinutes(), position.getSeconds())
    @$(".remaining").text _.sprintf("%d:%02d", duration.getMinutes(), duration.getSeconds())
```

Likewise, for a view referring to a `playable` model:

```
class App.View.Track extends Backbone.View
  initialize: ->
    @model.bind "paused",   @paused
    @model.bind "played",   @played
    @model.bind "resumed",  @played
    @model.bind "stopped",  @stopped
    @model.bind "finished", @finished
```

backbone.modelizer
------------------

If `backbone.modelizer` is installed, `playable.retain()` will be called when `playable` is
being played and `playable.release()` will be called when `playable` is being released.

Using
=====

Just include `backbone.soundmanager2.js` after including `backbone.js` and `soundManager2` and before 
any code that makes use of it and you're ready to go!
