require 'open-uri'

class YoutubeplaylistController < ApplicationController
  def index
  end
  def playlist
    $links = Array.new
    $link = params['link']
    $count = -1
    $site = open($link)
    $doc = Hpricot($site)
    $doc.search("a[$href]").each do |href|
      $links << href.to_s
    end
    $youtubes = Array.new
    $links.each do |link|
      if link.match("http:\\/\\/www\\.youtube\\.com\\/watch\\?v=")
        $youtubes << link
      end
    end
    $youtubecodes = Array.new
    $youtubes.each do |yt|
      $youtubecodes << yt.gsub(/.*v=([^&]+).*$/i, '\1').to_s[0..10]
    end
    $youtubecodes.uniq!
    $durations = Array.new
    $durations << 5
    $youtubecodes.each do |ytc|
      video = Hpricot.XML(open("http://gdata.youtube.com/feeds/api/videos/#{ytc}"))
      $durations << video.at("yt:duration").attributes['seconds']
    end
    $number = $youtubecodes.length
    puts $youtubecodes
  end
  def youtubeframe
    $count += 1
    $time = Array.new
    $durations.each do |d|
      $time << d
    end
    $youtubeurl = ["http://www.whatismyip.org"]
    $youtubecodes.each do |ytc|
      $youtubeurl << "http://www.youtube.com/v/#{ytc}"
    end
  end
end