require 'rubygems'
require 'activesupport'
require 'appscript'
require 'track'
require 'core_extensions'
require 'library'

class ITunes
  include Library
  
  SERVER_PLAYLIST_NAME = 'controllercontroller'
  MIN_VOLUME = 0
  MAX_VOLUME = 100
  
  def initialize
    init_playlist
    playpause
  end
  
  def app
    @app ||= itunes_connection
  end
  
  def server_playlist
    playlists[SERVER_PLAYLIST_NAME]
  end
  
  def add_track(track_index)
    app.tracks[track_index.to_i].duplicate(:to => server_playlist)
  end
  
  def remove_track(track_index)
    current_tracks_ref[track_index.to_i].delete
  end
  
  def add_album(name)
    find_tracks_by_album(name).each do |track|
      add_track(track.library_index)
    end
  end
  
  def clear_playlist
    current_tracks_ref.delete
  end
  
  def current_playlist
    begin
      app.current_playlist.get
    rescue Appscript::CommandError
      init_playlist
      playpause
      retry
    end    
  end
  
  def current_tracks_ref
    current_playlist.tracks
  end
  
  def current_tracks
    current_tracks_ref.get.map{|t| Track.new(t)}
  end
  
  def current_tracks_with_indexes
    current_tracks.zip(current_tracks_ref.index.get)
  end
  
  def playlist_names
    playlists.keys
  end
  
  def playlists
    app.user_playlists.get.inject({}) do |playlists, list|
      playlists.merge(list.name.get => list)
    end
  end
  
  def current_track
    begin
      Track.new(app.current_track.get)
    rescue Appscript::CommandError
      playpause
      retry
    end
  end
  
  def time_left_in_current_track
    seconds = (current_track.duration - app.player_position.get)
    "%i:%02i" % [seconds / 60, seconds % 60]
  end
  
  def player_state
    app.player_state.get
  end
  
  def increase_volume(incr)
    new_volume = @volume_before_mute || (current_volume + incr).at_most(MAX_VOLUME)
    app.sound_volume.set(new_volume)
  end
  
  def decrease_volume(incr)
    new_volume = (current_volume - incr).at_least(MIN_VOLUME)   
    app.sound_volume.set(new_volume)
  end
  
  def mute
    @volume_before_mute = current_volume
    app.sound_volume.set(0)
  end
  
  def muted?
    current_volume == MIN_VOLUME
  end  
  
  def unmute
    app.sound_volume.set(@volume_before_mute.to_i)
    @volume_before_mute = nil
  end
  
  def current_volume
    app.sound_volume.get
  end
  
  def play
    app.play
  end
  
  def pause
    app.pause
  end
  
  # ensure there's a current_track and current_playlist
  def playpause
    if app.player_state == :stopped
      app.play(server_playlist)
      app.pause
    end
  end
  
  def add_default_track
    add_track(1)
  end
  
  def create_playlist
    app.user_playlists.make(:new => :playlist, :with_properties => {:name => SERVER_PLAYLIST_NAME})
  end
  
  def server_playlist_exists?
    playlist_names.include?(SERVER_PLAYLIST_NAME)
  end
  
  def init_playlist
    create_playlist unless server_playlist_exists?
    add_default_track if playlist_empty? 
  end
  
  def playlist_empty?
    !server_playlist.tracks.get.any?
  end
  
  def itunes_connection
    Appscript.app('iTunes')
  end  
end