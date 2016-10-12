# frozen_string_literal: true

require 'json'
require 'rubygems'
require 'bundler/setup'
Bundler.setup
require 'dotenv'
Dotenv.load

require_relative 'lib/national_rail_notifier'

file = File.read('trains.json')

config = JSON.parse(file)

config.each do |options|
  NationalRailNotifier.run(options)
end
