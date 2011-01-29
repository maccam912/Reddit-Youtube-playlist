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
      $doc = Nokogiri::HTML($site)
      $doc.search("a[href]").each do |href|
        $links << href.to_s
      end
      if $pagestart == 1
        $link = $doc.xpath("//html/body/div[4]/p/a").to_s[9..-31]
      elsif $pagestart != 1
        $link = $doc.xpath("//html/body/div[4]/p/a[2]").to_s[9..-31]
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
    $durations << "3"
    $titles = Array.new
    $titles << "Loading..."
    $youtubecodes.each do |ytc|
      puts ytc
      begin
        video = Nokogiri::XML(open("http://gdata.youtube.com/feeds/api/videos/#{ytc}"))
      rescue
        puts "Error while opening id #{ytc}"
        $youtubecodes.delete("#{ytc}")
        next
      end
      $durations << video.xpath("//yt:duration").to_s[22..24].to_i
      $titles <<  video.search("title").text
    end
    puts $durations
    $number = $youtubecodes.length
  end
  def youtubeframe
    $count += 1
    $time = Array.new
    $durations.each do |d|
      $time << (d.to_i + 2)
    end
    $youtubeurl = ["http://www.whatismyip.org"]
    $youtubecodes.each do |ytc|
      $youtubeurl << "http://www.youtube.com/v/#{ytc}"
    end
  end
end