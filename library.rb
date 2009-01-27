require 'track'
require 'uri'
require 'rubygems'
require 'activesupport'

module Library
  
  def library_playlist
    app.library_playlists[1]
  end
  
  def artists
    app.tracks.artist.get.uniq!.reject{|a| a.blank?}.sort_by(&:upcase)
  end
  
  def artist_letters
    artists.map{|a| a[0,1].upcase}.uniq
  end
  
  def albums
    app.tracks.album.get.uniq
  end
  
  def find_tracks_by_artist(artist)
    search(artist, :artists)
  end
  
  def find_albums_by_artist(artist)
    find_tracks_by_artist(artist).group_by(&:album)
  end
  
  def find_tracks_by_album(album)
    search(album, :albums)
  end
  
  def search(what, where = nil)
    opts = {:for => what}
    opts[:only] = where if where
    library_playlist.search(opts).map{|t| Track.new(t)}
  end
  
end