require 'rubygems'
require 'activesupport'
require 'sinatra'
require 'json'
require 'itunes'
require 'uri'

configure do
  ITUNES = ITunes.new
  use_in_file_templates!
end

helpers do
  def itunes
    ITUNES
  end
  
  def current_track
    itunes.current_track
  end
  
  def current_playlist
    itunes.current_playlist
  end
  
  def current_tracks
    itunes.current_tracks
  end
  
  def current_tracks_with_indexes
    itunes.current_tracks_with_indexes
  end
  
  def library_artists
    itunes.artists
  end
  
  def library_albums
    itunes.albums
  end
  
  def link_to(label, url = '/')
    if url.is_a?(Hash)
      url[:return] = request.url
      url = '?' + url.to_param
    end
    
    "<a href=\"#{URI.escape(url)}\">#{label}</a>"
  end
end

get '/stylesheet.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :stylesheet
end

get '/*' do
  if itunes.player_state == :stopped && !itunes.playlist_empty?
    itunes.playpause
  end
  
  case params[:do]
  when 'play'
    itunes.play
  when 'pause'
    itunes.pause
  when 'volume_up'
    itunes.increase_volume(5)
  when 'volume_down'
    itunes.decrease_volume(5)
  when 'mute'
    itunes.mute
  when 'unmute'
    itunes.unmute  
  when 'remove'
    itunes.remove_track(params[:index].to_i)
  when 'add'
    itunes.add_track(params[:index].to_i)
  end
  
  if params[:do]
    redirect URI.unescape(params[:return] || '/')
  else
    haml :dashboard
  end
end
