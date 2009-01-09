require 'rubygems'
require 'activesupport'
require 'appscript'
require 'track'

class ITunes
  SERVER_PLAYLIST_NAME = 'controllercontroller'
  
  def initialize
    create_playlist unless playlist_exists?
  end
  
  def app
    @app ||= itunes_connection
  end
  
  def playlist
    playlists[SERVER_PLAYLIST_NAME]
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
      app.current_track.get
    rescue Appscript::CommandError
      playpause
      retry
    end
  end
  
  def itunes_connection
    Appscript.app('iTunes')
  end
  
  # ensure there's a current_track and current_playlist
  def playpause
    app.play
    app.pause
  end 
  
  def create_playlist
    app.user_playlists.make(:new => :playlist, :with_properties => {:name => SERVER_PLAYLIST_NAME})
  end
  
  def playlist_exists?
    playlist_names.include?(SERVER_PLAYLIST_NAME)
  end
end

@it = ITunes.new