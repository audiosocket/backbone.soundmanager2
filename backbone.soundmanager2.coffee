if require?
  Backbone = require "backbone"
else
  Backbone = window.Backbone

# A player model for use with SoundManager2 API.  Requires soundmanager2 (duh).

class Backbone.SoundManager2
  _.extend this.prototype, Backbone.Events

  # Create a new Player instance. There will probably only ever be one
  # of these in the app. If `options.bus` is provided, rebroadcast all events
  # to it with a `player:` prefix.  Can also accept an 'autoPlay' option if
  # you want the sound to start playing automatically on load.
  #
  # Also rebroadcast messages on the playable, if possible.
  #
  # Examples
  #
  #   track = new Track()
  #   track.on "player:heyo", myFunction
  #
  #   player = new Player()
  #   player.playable = track
  #   player.trigger "heyo"
  #    # => Will execute track.myFunction()
  #
  # Returns self.

  constructor: (options = {}) ->
    @options = options

    if @options.bus?
      @on "all", (event, args...) ->
        @options.bus.trigger "player:#{event}", args...

    @on "all", (event, args...) ->
      return unless @playable?.trigger?

      @playable.trigger "player:#{event}", args...

    this


  # Release the current sound, clear the current playable, and trigger
  # a `released` event.
  #
  # Examples
  #
  #   App.player.release() # => Playable is removed from player.
  #
  # Returns newly changed self.

  release: ->
    @fadeout() if @sound

    @sound = null

    @trigger "releasing"

    @playable.release() if @playable?.release?
    @playable = null

    @trigger "released"

    this

  # Fade out the current sound's volume to 0 and destroy it.
  #
  # Examples
  #
  #   player.fadeout() # => volume smoothly goes to zero.
  #
  # Returns self

  fadeout: ->
    s = @sound
    vol = @volume * 100

    fnc = =>
      vol -= 2
      s.setVolume vol
      if vol > 0
        _.delay fnc, 10
      else
        s.destruct()

    fnc()

    this


  # Determine if the state of the player is `paused`, or `playing`.
  #
  # Examples
  #
  #   player.toggle track
  #   player.getState() # => "playing"
  #
  # Returns String indicating `paused` or `playing` state.
  # Returns null if nothing is currently playing.

  getState: ->
    return unless @playable?

    return "loading" unless @sound?

    return "stopped" if @sound.playState == 0

    if @sound.paused then "paused" else "playing"


  # Determine if current playable is equal to playable passed in.
  #
  # Examples
  #
  #   player.load track
  #   player.isAlreadyPlaying track # => true
  #
  # Returns boolean.

  isAlreadyPlaying: (playable) ->
    @playable? and @playable.id == playable.id



  # Test if a `playable` has getAudioURL() method.
  #
  # playable - A model that fulfills the contract of having getAudioURL()
  #
  # Examples
  #
  #   track = new Track();
  #   track.isPlayable() # => true
  #
  # Returns boolean.

  isPlayable: (playable) ->
    playable.id? and playable.getAudioURL?


  ok: ->
    soundManager.ok()

  # Load a `playable` and create an SM2 sound instance (@sound) to represent it.
  # Triggers `loading` and `loaded` events.  Will also automatically play
  # it's `playable` model.
  #
  # playable - A model that fulfills the contract of having getAudioURL()
  #
  # Examples
  #
  #   track = new Track();
  #   player.load track

  load: (playable) ->
    # No need to load the same playable track
    return if playable is @playable

    unless soundManager.ok()
      return @trigger "error", "SoundManager2 isn't ready."

    unless @isPlayable playable
      return @trigger "error",
        "Playable doesn't satisfy the contract.", playable

    @release()

    @playable = playable
    @playable.retain() if @playable.retain?

    @trigger "loading"

    playable.getAudioURL (url) =>
      # It may happen that the playable has
      # changed while fetching url..
      return unless @playable == playable

      @sound = soundManager.createSound
        autoPlay     : false # Trick: we want the "played" event
                             # to be emitted after the "loaded"
                             # event, so we call `@sound.play()`
                             # manually below..
        id           : playable.id
        url          : url
        volume       : Math.round @volume*100
        onfinish     : => @trigger "finished",    @sound
        onplay       : => @trigger "played",      @sound
        onpause      : => @trigger "paused",      @sound
        onresume     : => @trigger "resumed",     @sound
        onstop       : => @trigger "stopped",     @sound
        whileplaying : => @trigger "playing",     @sound
        whileloading : => @trigger "bytesLoaded", @sound

      @trigger "loaded", @sound

      @sound.play() if @options.autoPlay is true

  # Initial volume

  volume: 1

  # Set sound to be a particular volume, accepts values
  # between 0. and 1.
  #
  # volume - a float between 0 and 1.
  #
  # Examples
  #
  #   player.sound.volume # => 80
  #   player.setVolume 1
  #   player.sound.volume # => 100
  #
  # Returns SoundManager2 sound.

  setVolume: (volume) ->
    return unless @sound?
    return if volume > 1 || volume < 0

    @volume = volume
    @sound.setVolume Math.round(@volume * 100)
    @sound



  # Move to a specific position in the current sound. `position` is a
  # percentage, expressed as a number between 0 and 1.
  #
  # position - a float between 0 and 1.
  #
  # Examples
  #
  #   # for a track with a duration of 5000 milliseconds
  #   player.sound.position # => 1000
  #   player.setPosition 0.5
  #   player.sound.position # => 2500
  #
  # Returns SoundManager2 sound.

  setPosition: (position) ->
    return unless @sound?
    return if @sound.bytesLoaded / @sound.bytesTotal < position
    @sound.setPosition position * @sound.durationEstimate
    @sound

  # Move to a position relative to current position, in milliseconds
  #
  # position - a integer..
  #
  # Examples
  #
  #   # For a track with a duration of 5000 milliseconds
  #   player.sound.position # => 1000
  #   player.setRelativePosition -500
  #   player.sound.position # => 500

  setRelativePosition: (position) ->
    return unless @sound?

    @sound.setPosition @sound.position + position


  # Toggle play/pause for the current sound or load a new `playable`.
  #
  # playable - A model that fulfills the contract of having getAudioURL()
  #
  # Examples
  #
  #   player.toggle track # => track will load and start playing

  toggle: (playable = @playable) ->
    if @sound? and @isAlreadyPlaying playable
      @sound.togglePause()
    else if playable?
      @stop()
      @load playable


  # Stop for the current sound.
  #
  # Examples
  #
  #   player.stop() # => track will stop completely

  stop: ->
    return unless @sound?
    @sound.stop()
