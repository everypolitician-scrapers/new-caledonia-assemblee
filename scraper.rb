#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)

  noko.css('#table-elus tr').drop(1).map do |tr|
    tds = tr.css('td')
    family_name = tds[0].text.tidy
    given_name = tds[1].text.tidy
    datatab = noko.css(tds[4].css('a/@href').text)

    data = {
      id:          datatab.css('img/@class').text[/wp-image-(\d+)/, 1],
      name:        "#{given_name} #{family_name}",
      sort_name:   "#{family_name}, #{given_name}",
      family_name: family_name,
      given_name:  given_name,
      area:        tds[2].text.tidy,
      party:       tds[3].text.tidy,
      image:       datatab.css('img/@src').text,
      term:        '4',
      source:      url,
    }
    data[:image] = '' if data[:image].include?('no-elu.jpg') || data[:image].include?('img-elus.jpg')
    data
  end
end

data = scrape_list('http://www.congres.nc/assemblee/les-elus/?panel=5')
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[id term], data)
