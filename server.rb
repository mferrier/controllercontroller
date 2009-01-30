require 'rubygems'
require 'sinatra'
require 'activesupport'
require 'itunes'
require 'uri'
require 'helpers'

include Helpers

configure do
  ITUNES = ITunes.new
  use_in_file_templates!
end

get '/stylesheet.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :stylesheet
end

get '/*' do
  begin
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
    when 'set_volume'
      itunes.set_volume(params[:volume].to_i)
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
  
    if params[:artist]
      @albums = itunes.find_albums_by_artist(URI.unescape(params[:artist]))
    end

    if request.xhr?
      if params[:artist]
        partial :album, :locals => {:albums => (@albums || [])}
      else
        # render nothing
        nil
      end
    elsif params[:do]
      redirect request.referrer || '/'
    else
      haml(:dashboard) 
    end
  rescue Appscript::CommandError
    puts "retrying"
    itunes.reconnect and retry
  end
end