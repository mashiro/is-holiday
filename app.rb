#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'bundler'
Bundler.require
require 'uri'
require 'date'
require 'json'

helpers do
  def holiday?(day, ids)
    conn = Faraday.new url: 'http://www.google.com' do |faraday|
      faraday.request :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end

    ids.each do |id|
      url = "/calendar/feeds/#{URI.escape(id)}/public/full-noattendees"
      res = conn.get url,
        'start-min' => day.to_s,
        'start-max' => (day + 1).to_s,
        'alt' => 'json',
        'orderby' => 'starttime'

      entries = res.body['feed']['entry'] || []
      holidays = entries.map { |e| Date.parse e['gd$when'][0]['startTime'] }
      return true if holidays.include? day
    end

    false
  end

  def parse(key, options = {})
    value = params[key]
    if value.nil?
      options[:default]
    else
      yield value
    end
  end
end

get '/' do
  content_type :json
  begin
    day = parse('day', default: Date.today) { |v| Date.parse v }
    weekend = parse('weekend', default: [0, 6]) { |v| v.split(',').map { |v| Integer(v) } }
    ids = parse('ids', default: ['japanese__ja@holiday.calendar.google.com']) { |v| v.split(',') }

    if weekend.include? day.wday
      res = true
    else
      res = holiday? day, ids
    end
  rescue => e
    status 400
    res = {error: e.to_s}
  end

  JSON.dump res
end

