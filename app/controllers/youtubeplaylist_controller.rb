require 'open-uri'

class YoutubeplaylistController < ApplicationController
  def index
  end
  def playlist
    $link = params['link']
    $originallink = $link
    $pagestart = 1
    $pageend = params['pageend'].to_i
    $count = -1
    
    $totalyoutubes = Array.new
    $totalsoundclouds = Array.new
    
    $durations = Array.new
    $durations << 0
    $titles = Array.new
    $titles << "Loading..."
    
    #iterate through pages and collect links
    while ($pagestart <= $pageend) do
      $doc = Nokogiri::HTML(open($link))
      
      $links = Array.new
      $links = get_links($link)
      
      $youtubelinks = match_for_youtube($links)
      $soundcloudlinks = match_for_soundcloud($links)
      puts $link
      if $pagestart == 1
        $link = $doc.xpath("//html/body/div[4]/p/a").to_s[9..-31]
      elsif $pagestart != 1
        $link = $doc.xpath("//html/body/div[4]/p/a[2]").to_s[9..-31]
      end
      
      $pagestart += 1
      
      $totalsoundclouds = $totalsoundclouds + $soundcloudlinks
      $totalyoutubes = $totalyoutubes + $youtubelinks
    end
    $youtubes = $totalyoutubes
    $totalyoutubes = $totalyoutubes.uniq
    $soundclouds = $totalsoundclouds
    $totalsoundclouds = $totalsoundclouds.uniq
    
    #get links specifically from youtube, and get the ID from the links
    $youtubecodes = get_youtube_codes($youtubes)
     
    $soundcloudlinks = Array.new
    $soundclouds.each do |sc|
      $soundcloudlinks << extract_soundcloud_link(sc)
    end
    if $soundcloudlinks.compact
      $soundcloudlinks = $soundcloudlinks.compact
    end
    $soundcloudlinks.uniq!
    $numofsoundclouds = $soundcloudlinks.length
    
    #YOUTUBE SECTION
    $number = $numofyoutubes
    $url = ["http://www.riaa.com"]
    $numofyoutubes = 0
    $deletes = Array.new
    $youtubecodes.each do |ytc|
      puts ytc
      begin
        video = Nokogiri::XML(open("http://gdata.youtube.com/feeds/api/videos/#{ytc}"))
      rescue
        puts "Error while opening id #{ytc}"
        $deletes << $youtubecodes.index(ytc)
        $youtubecodes.delete(ytc)
        next
      end
      $numofyoutubes += 1
      $durations << video.xpath("//yt:duration").to_s[22..24].to_i
      $titles <<  video.search("title").text
      $url << "http://www.youtube.com/v/#{ytc}"
    end
    
    #SOUNDCLOUD SECTION
    
    $soundclouddurations = Array.new
    $soundcloudtitles = Array.new
    $soundcloudurls = Array.new
    $soundcloudlinks.each do |sc|
      begin
        soundcloud = Nokogiri::HTML(open("#{sc}"))
      rescue
        puts "Error while opening id #{sc}"
        $soundcloudlinks.delete("#{sc}")
        next
      end
      puts sc
      $soundcloudurls << get_soundcloud_code(sc)
      $soundclouddurations << (soundcloud.xpath("//html/body/div[2]/div/div/div/div[3]/div/div/span[2]").inner_html.strip.split(".")[0].to_i * 60) + (soundcloud.xpath("//html/body/div[2]/div/div/div/div[3]/div/div/span[2]").inner_html.strip.split(".")[1].to_i)
      $soundcloudtitles << soundcloud.xpath("//html/body/div[2]/div/div/div/div/h1/em").inner_html.strip
    end
    
    $soundcloudurls.each do |l|
      $url << l.to_s
    end
    
    
    $soundclouddurations.each do |d|
      $durations << d.to_s
    end
    $soundcloudtitles.each do |t|
      $titles << t.to_s
    end
    $number = $numofyoutubes + $numofsoundclouds
    
    puts "##########"
    puts $url.length
    puts $durations.length
    puts $titles.length
    puts $number
    puts $deletes
    puts "##########"
    
    #turn the arrays into CSVs to send to the client
    $urlcsv = $durationscsv = $titlescsv = ""
    
    $urlcsv = array_to_csv($url)
    $durationscsv = array_to_csv($durations)
    $titlescsv = array_to_csv($titles)

  end
  
  def youtubeframe
    
    #if client-side should have the arrays saved as CSVs, turn CSVs back onto arrays
    #number should be taken from client-side too so an accurate playlist length count is possible
    if $count > 0
      $titles = csv_to_array(params['title_array'])
      $durations = csv_to_array(params['duration_array'])
      $url = csv_to_array(params['url_array'])
      $number = params['number'].to_i
    end
    
    #get count from client-side if client-side should have one
    if $count >= 0
      $count = params['count'].to_i
    end
    
    #go to next song
    $count += 1
    
    #send a CSV client-side to save the values in case they change server-side
    $urlcsv = array_to_csv($url)
    $durationscsv = array_to_csv($durations)
    $titlescsv = array_to_csv($titles)
    
  end
end


def array_to_csv(arrayvar)
  csvvar = ""
  arrayvar.each do |var|
    csvvar = csvvar + "#{var}, "
  end
  return csvvar
end

def csv_to_array(csvvar)
  arrayvar = csvvar.split(',').collect {|h| h.strip}
  arrayvar.delete("")
  arrayvar.delete (" ")
  return arrayvar
end

def get_links(source = "http://www.whatismyip.org/")
  array_of_links = Array.new
  site = open(source)
  doc = Nokogiri::HTML(site)
  doc.search("a[href]").each do |href|
    array_of_links << href.to_s
  end
  return array_of_links
end

def match_for_youtube(array)
  youtubes = Array.new
  array.each do |link|
    if link.match("http:\\/\\/www\\.youtube\\.com\\/watch\\?v=")
      youtubes << link
    end
  end
  return youtubes
end

def get_youtube_codes(array)
  youtubecodes = Array.new
  array.each do |yt|
    youtubecodes << yt.gsub(/.*v=([^&]+).*$/i, '\1').to_s[0..10]
  end
  youtubecodes.uniq!
  return youtubecodes
end

def match_for_soundcloud(array)
  soundclouds = Array.new
  array.each do |link|
    if link.match("http:\\/\\/soundcloud\\.com")
      soundclouds << link
    end
  end
  return soundclouds
end

def extract_soundcloud_link(html)
  html.split("\"")[3]
end

def get_soundcloud_code(link)
  site = open(link)
  doc = Nokogiri::HTML(site)
  code = doc.css("html body#tracks.show div#main-wrapper div#main-content div#main-content-inner div.player").to_s.split("\"")[3]
  puts code
  return code
end