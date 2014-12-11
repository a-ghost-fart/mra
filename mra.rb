require 'nokogiri'
require 'sinatra'
require 'json'
require 'marky_markov'
require 'open-uri'

class MRA
    def initialize(pages)
        @pages = pages
        @markov = MarkyMarkov::Dictionary.new('dictionary', 3)
        @avfm_docs = get_avfm_pages
        @rmr_docs = get_rmr_pages
    end

    def get_rmr_pages
        docs = Array.new
        i = 0
        offset = 0
        while i < @pages do
            temp_json = JSON.parse(open("http://api.reddit.com/r/mensrights/.json?limit=100&after=#{offset}").read)
            if temp_json['data']['children'].length == 0
                i = @pages
            else
                offset = 't3_' + temp_json['data']['children'].last['data']['id']
                docs.push temp_json
                i += 1
            end
        end
        return docs
    end

    def get_avfm_pages
        titles = Array.new
        doc = Nokogiri::XML(open('https://avoiceformen.com/comments/feed/'))
        doc.xpath('//channel/item/description').each do |item|
            titles.push item.text
        end
        return titles
    end

    def load_dictionaries
        @rmr_docs.each do |doc|
            doc['data']['children'].each do |item|
                @markov.parse_string item['data']['title']
            end
        end
        @avfm_docs.each do |comment|
            @markov.parse_string comment
        end
    end

    def get_line
        @markov.generate_n_sentences 1
    end
end

mra = MRA.new 10
mra.load_dictionaries

get '/mra' do
    mra.get_line
end
