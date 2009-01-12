require 'rubygems'
require 'activesupport'
require 'sinatra'
require 'itunes'
require 'uri'
require 'ruby-debug'

configure do
  ITUNES = ITunes.new
  use_in_file_templates!
end

helpers do
  def itunes
    ITUNES
  end
  
  def link_to(label, url = '/')
    if url.is_a?(Hash)
      url = '?' + url.to_param
    end
    
    "<a href=\"#{URI.escape(url)}\">#{label}</a>"
  end
  
  def partial(page, options={})
    haml "_#{page.to_s}".to_sym, options.merge!(:layout => false)
  end
  
  def link_to_anchor(label, name)
    url = "##{name}"
    link_to label, url
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
  when 'skip'
    itunes.server_playlist.tracks[params[:index].to_i].play
  when 'add_album'
    itunes.add_album(URI.unescape(params[:album]))
  when 'clear'
    itunes.clear_playlist
  end
  
  if params[:do]
    redirect request.referrer || '/'
  else
    haml :dashboard
  end
end
