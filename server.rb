require 'rubygems'
require 'activesupport'
require 'sinatra'
require 'json'
require 'itunes'

ITUNES = ITunes.new
use_in_file_templates!

helpers do
  def itunes
    Appscript.app("iTunes")
  end
  
  def show_current_track
    t = itunes.current_track
    out = []
    if t.name.exists
      name = t.name.get
      out << "   Title:  #{(name == '') ? 'Unknown' : name}"
      [
          ['  Artist', t.artist.get], 
          ['   Album', t.album.get], 
          ['Composer', t.composer.get],
          ].each do | label, text|
        if text != ''
          out << "#{label}:  #{text}"
        end
      end
      s = t.duration.get() - itunes.player_position.get
      out << "Duration:  %s  (%i:%02i remaining)" % [t.time.get, s / 60, s % 60]
      out << "Playlist:  #{itunes.current_playlist.name.get}"
    else
      out << 'No track selected.'
    end
    out.join("<br />")
  end
end

get '/dashboard' do
  if itunes.player_state.get == :stopped
    itunes.play
    itunes.pause
  end
  
  haml :dashboard
end

# get '/*' do
#   redirect '/dashboard'
# end
