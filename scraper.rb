#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)

  noko.css('#table-elus tr').drop(1).each do |tr|
    tds = tr.css('td')
    family_name = tds[0].text.tidy
    given_name = tds[1].text.tidy
    datatab = noko.css(tds[4].css('a/@href').text)

    data = { 
      id: datatab.css('img/@class').text[/wp-image-(\d+)/, 1],
      name: "#{given_name} #{family_name}",
      sort_name: "#{family_name}, #{given_name}",
      family_name: family_name,
      given_name: given_name,
      area: tds[2].text.tidy,
      party: tds[3].text.tidy,
      image: datatab.css('img/@src').text,
      term: '4',
      source: url,
    }
    data[:image] = '' if data[:image].include?('no-elu.jpg') || data[:image].include?('img-elus.jpg')
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

scrape_list('http://www.congres.nc/assemblee/les-elus/?panel=5')
