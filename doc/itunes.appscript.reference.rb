#!/usr/bin/env ruby

# itunes -- A command-line interface for Mac OS X iTunes
#
# Copyright (C) 2007 HAS
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.



# REQUIREMENTS
#
#    *   Ruby 1.8+
#
#    *   rb-appscript (http://rb-appscript.rubyforge.org)
#
#    *   readline support (this is recommended, but not essential)


######################################################################

Version = '1.0.1'

######################################################################

begin
  require 'rubygems' # clients may have installed appscript via RubyGems
rescue LoadError
end

begin
  require 'readline'
  include Readline
rescue LoadError
  def readline(*args)
    print '> '
    return gets
  end
end

require 'getoptlong'

require 'appscript'
include Appscript


######################################################################
# help

Help = <<-EOS
itunes -- command-line interface for iTunes

USAGE

    itunes [ -a address ] [ -h ] [ command ]

DESCRIPTION

itunes provides a convenient command-line interface for controlling iTunes
on Mac OS X.

The following options are available:

    -a address    The IP number or Bonjour address for a Mac OS X machine on 
                  which iTunes is running.
    
    -h            Show this help.

    -v            Show itunes' version number.

If the -h option or a command is given, itunes performs the appropriate action
and exits, otherwise it enters interactive mode.

COMMANDS

(Note that most commands can be written in abbreviated form; valid forms are 
shown separated by commas.)

Play/Pause Commands

    play     Play the current track.
    
    pause    Pause the current track.
    
    p        Toggle the current track between play and pause.

Information Commands

    i, info, information     Show the current track's title, artist, album, 
                             composer, duration and playlist.
    
    pl, playlist [ name ]    List the named playlist's tracks. If no name is
                             given, the current playlist is shown.
    
    s, search [ ( all | titles | artists | albums | composers ) for ] text

                             Search for the given text in the specified
                             field(s) of the current playlist. If a field
                             isn't specified, "all" is used.

Navigation Commands
    
    b, back             Go back to the start of the current track.

    pr, previous        Go to the previous track.
    
    n, next             Go to the next track.
    
    r, random           Go to a random track.
    
    rw, rewind          Rewind through tracks. (Type Return/Enter to resume
                        normal play.)

    ff, fast forward    Fast forward through tracks. (Type Return/Enter to 
                        resume normal play.)
    
    g, goto [ p, playlist | t, track ] name

                        Go to the specified playlist, or a track in the 
                        current playlist. If neither "playlist" nor "track"
                        is indicated, "track" is used.

Configuration Commands

    v, volume [ level ]       Set the volume (level = 0 to 10). If no level
                              is given, the current volume is displayed.
    
    eq, equalizer [ name ]    Set the equalizer to use. If no name is given,
                              the current equalizer's name is shown.
    
Miscellaneous Commands

    a, activate    activate iTunes

    h, help        show this help
    
    q, quit        exit

NOTES
    
    *   The playlist and equalizer commands can accept "?" instead of a name
        to list all available playlists/equalizers, e.g. equalizer ?

    *   The playlist, goto and equalizer commands can accept an index number
        instead of a name, e.g. playlist 3

    *   The playlist, goto and equalizer commands support wildcard completion
        ("*"), e.g. goto playlist top*
    
    *   The search command's "titles", "artists", "albums" and "composers"
        arguments can each be abbreviated to the first three letters
        (i.e. tit, art, alb, com).
    
    *   Commands can be abbreviated and whitespace between commands and
        arguments omitted as long as this doesn't cause any ambiguity.

EXAMPLES

itunes              # run in interactive mode
> playlist?         # list all playlists
> gp Top 25*        # go to playlist named "Top 25..." and start playing it
> pause             # pause iTunes
> next              # go to next track      
> p                 # toggle from paused to playing
> s com for bach    # search current playlist's composers field for "bach"
> g10               # go to track 10 in the playlist
> random            # go to a random track in iTunes' Library
> q                 # quit

itunes p            # toggle iTunes between playing and paused

itunes pl party\*         # list the playlist named "party..."

itunes v11          # set maximum volume

EOS


######################################################################
# support functions

def show_track_info(i, name, artist, album)
  if name == ''
    name = '???'
  end
  if artist == ''
    artist = '???'
  end
  if album == ''
    album = '???'
  end
  puts "%4i %-30.30s  %-20.20s  %-20.20s" % [i, name, artist, album]
end

def show_current_track
  t = ITunes.current_track
  if t.name.exists
    name = t.name.get
    puts "   Title:  #{(name == '') ? 'Unknown' : name}"
    [
        ['  Artist', t.artist.get], 
        ['   Album', t.album.get], 
        ['Composer', t.composer.get],
        ].each do | label, text|
      if text != ''
        puts "#{label}:  #{text}"
      end
    end
    s = t.duration.get() - ITunes.player_position.get
    puts "Duration:  %s  (%i:%02i remaining)" % [t.time.get, s / 60, s % 60]
    puts "Playlist:  #{ITunes.current_playlist.name.get}"
  else
    puts 'No track selected.'
  end
end

def expand_name(ref, name)
  if /^[0-9]+$/ === name
    return ref[name.to_i]
  elsif /\*$/ === name
    return ref[its.name.begins_with(name.chop)].first
  else
    return ref[name]
  end
end


######################################################################
# parse command options, if any

address = nil

opts = GetoptLong.new(
    ["-a", GetoptLong::REQUIRED_ARGUMENT],
    ["-h", GetoptLong::NO_ARGUMENT],
    ["-v", GetoptLong::NO_ARGUMENT]
    )

begin
  opts.each do |opt, arg|
    case opt
      when '-a'
        address = "eppc://#{arg}/iTunes"
      when '-h'
        puts Help
        exit
      when '-v'
        puts Version
        exit
    end
  end
rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument
  exit
end

if address
  ITunes = app.by_url(address)
else
  ITunes = app('ITunes')
end


######################################################################
# commands

def do_command(line)
  case line.strip
    # play/pause
    when 'play'
      ITunes.play
      show_current_track
    when 'pause'
      ITunes.pause
      puts 'Paused.'
    when 'p'
      # iTunes' playpause command is a bit flaky and may forget the current track, so use play and pause commands here
      if ITunes.player_state.get == :playing
        ITunes.pause
        puts 'Paused.'
      else
        ITunes.play
        show_current_track
      end
    
    # info
    when 'i', 'info', 'information'
      show_current_track
    when /^pl(?:aylist)? *(.*)/
      name = $1
      if name == '?' # list all playlist names
        ref = ITunes.playlists
        ref.index.get.zip(ref.name.get).each { |i, name| puts "%4i %s" % [i, name] }
      else
        if name == '' # list current playlist tracks
          ref = ITunes.current_playlist
        else # list named playlist's tracks
          ref = expand_name(ITunes.playlists, name)
        end
        if ITunes.player_state.get == :stopped # if iTunes is stopped then current playlist doesn't exist, so put it into pause
          ITunes.play
          ITunes.pause
        end
        puts ref.name.get
        t = ref.tracks
        if t.exists # iTunes stupidly throws error when getting elements' properties if no elements found, so make sure there's one or more track elements in the playlist first
          len = ref.count(:each=>:track)
          if len > 50
            puts "#{len} tracks were found. Display them all? (y/n)"
            return if not /^y(?:es)?$/ === readline('> ', false).strip
          end
          t.index.get.zip(t.name.get, t.artist.get, t.album.get).each do |i, name, artist, album|
            show_track_info(i, name, artist, album)
          end
        else
          puts 'No tracks found.'
        end
      end
    when /^s(?:earch)? *(?:(tit(?:les?)?|alb(?:ums?)?|all|art(?:ists?)?|com(?:posers?)?) *for)? *(.+)/
      if ITunes.player_state.get == :stopped # if iTunes is stopped then current playlist doesn't exist, so put it into pause
        ITunes.play
        ITunes.pause
      end
      where, text = $1, $2
      case where
        when /^alb/
          where = :albums
        when /^art/
          where = :artists
        when /^com/
          where = :composers
        when /^tit/
          where = :songs
      else
        where = :all
      end
      found = ITunes.current_playlist.search(:for=>text, :only=>where)
      if found.length == 0
        puts 'No tracks found.'
      elsif found.length > 50
        puts "#{found.length} tracks were found. Display them all? (y/n)"
        return if not /^y(?:es)?$/ === readline('> ', false).strip
      end
      found.each { |t| show_track_info(t.index.get, t.name.get, t.artist.get, t.album.get) }
    
    # navigation
    when 'pr', 'previous'
      ITunes.previous_track
      show_current_track
    when 'n', 'next'
      ITunes.next_track
      show_current_track
    when 'r', 'random'
      ITunes.library_playlists[1].tracks.any.play
      show_current_track
    when 'b', 'back'
      ITunes.back_track
      show_current_track
    when 'ff', /fast *forward/
      ITunes.play
      print 'Fast forwarding... Return/Enter to resume'
      ITunes.fast_forward
      readline('> ', false)
      ITunes.resume
      show_current_track
    when 'rw', 'rewind'
      ITunes.play
      print 'Rewinding... Return/Enter to resume'
      ITunes.rewind
      readline('> ', false)
      ITunes.resume
      show_current_track
    when /^g(?:oto)? *(p(?:laylist)?|t(?:rack)?)? *(.+)/
      selector = $1
      if selector
        selector = selector[0,1]
      end
      name = $2
      if selector == 'p'
        ref = ITunes.playlists
      else
        ref = ITunes.current_playlist.tracks
      end
      ref = expand_name(ref, name)
      if ref.exists
        ref.play
        show_current_track
      else
        puts "#{selector == 'p' ? 'Playlist' : 'Track'} \"#{name}\" not found."
      end
    
    # configuration
    when /^v(?:olume)? *([0-9]|10|11)?$/
      level = $1
      if level != nil
        ITunes.sound_volume.set(level.to_i * 10)
      end
      puts (ITunes.sound_volume.get() +1) / 10
    when /^eq(?:ualizer)? *(.*)/
      name = $1
      if name == ''
        puts ITunes.current_EQ_preset.name.get
      elsif name == '?'
        names = ITunes.EQ_presets.name.get
        names.each_with_index do |name, i|
          puts "%4i %s" % [i + 1, name]
        end
      else
        eq = expand_name(ITunes. EQ_presets, name)
        if eq.exists
          ITunes.current_EQ_preset.set(eq.get)
          puts ITunes.current_EQ_preset.name.get
        else
          puts "Equalizer \"#{name}\" not found."
        end
      end
    
    # miscellaneous
    when 'a', 'activate'
      ITunes.activate
      ITunes.browser_windows.visible.set(true)
    when 'h', 'help'
      puts Help
    when 'q', 'quit'
      exit
  else
    puts 'Unknown command.'
  end
end


######################################################################
# start interactive interface/do one command

if ARGV == []
  while line = readline('> ', true)
    do_command(line)
  end
  puts
else
  do_command(ARGV.join(' '))
end
