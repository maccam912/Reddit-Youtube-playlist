require 'open-uri'

class YoutubeplaylistController < ApplicationController
  def index
  end
  def playlist
    $links = Array.new
    $link = params['link']
    $originallink = $link
    $pagestart = 1
    $pageend = params['pageend'].to_i
    $count = -1
    while ($pagestart <= $pageend) do
      $site = open($link)
      $doc = Hpricot($site)
      $doc.search("a[$href]").each do |href|
        $links << href.to_s
      end
      if $pagestart == 1
        $link = $doc.at("//html/body/div[4]/p/a")['href']
      elsif $pagestart != 1
        $link = $doc.at("//html/body/div[4]/p/a[2]")['href']
      end
      puts $link
      $pagestart += 1
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
    $durations << 2
    $titles = Array.new
    $titles << "Loading..."
    $youtubecodes.each do |ytc|
      puts ytc
      begin
        video = Hpricot.XML(open("http://gdata.youtube.com/feeds/api/videos/#{ytc}"))
      rescue
        puts "Error while opening id #{ytc}"
        $youtubecodes.delete("#{ytc}")
        next
      end
      $durations << video.at("yt:duration").attributes['seconds']
      $titles <<  video.search("title").inner_html
    end
    $number = $youtubecodes.length
  end
  def youtubeframe
    $count += 1
    $time = Array.new
    $durations.each do |d|
      $time << (d.to_i + 3)
    end
    $youtubeurl = ["http://www.whatismyip.org"]
    $youtubecodes.each do |ytc|
      $youtubeurl << "http://www.youtube.com/v/#{ytc}"
    end
  end
end