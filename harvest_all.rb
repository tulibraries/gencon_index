#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load'
require_relative 'lib/harvest_csv'

Dotenv.load

files = Dir['/tmp/gencon/*.csv']
files.sort.each do |fn|
  fp = File.expand_path(fn)
  puts "process #{fp}"
  command = [
    './csv2solr',
    'harvest',
    "'#{fp}'",
    '--mapfile=./solr_map.yml',
    "--solr-url=#{ENV.fetch('SOLR_URL', nil)}"
  ].join(' ')
  puts command
  `#{command}`
end
