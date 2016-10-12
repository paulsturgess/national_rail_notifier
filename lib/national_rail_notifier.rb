# frozen_string_literal: true
require 'date'
require 'logger'
require 'twitter'
require_relative 'national_rail_request'

# Checks the service status and tweets (if appropriate)
class NationalRailNotifier
  attr_reader :options

  def self.run(options)
    new(options).run
  end

  def initialize(options)
    @options = options
  end

  def run
    return if cannot_run? || !post_the_status?
    post_notification(service.status)
  end

  private

  def post_notification(status)
    logger.info "service.status: #{service.status}"
    twitter_account.update(status)
  end

  def post_the_status?
    !on_time? && !status_already_tweeted? && new_status?
  end

  def cannot_run?
    weekend? || !service
  end

  def service
    @service ||= NationalRailRequest.check_service(options)
  end

  def weekend?
    [6, 0].include? Date.today.wday
  end

  def latest_tweets
    twitter_account.user_timeline.first(5)
  end

  def twitter_account
    @twitter_account ||= Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_NOTIFIER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_NOTIFIER_CONSUMER_SECRET']
      config.access_token = ENV['TWITTER_NOTIFIER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_NOTIFIER_ACCESS_TOKEN_SECRET']
    end
  end

  def logger
    @logger ||= Logger.new('log/application.log', 'daily')
  end

  def status_already_tweeted?
    latest_tweets.any? do |tweet|
      service.status == tweet.text &&
        tweet.created_at.day == Time.now.day
    end
  end

  def new_status?
    service.status != latest_tweets.first.text
  end

  def on_time?
    service.status == 'On time'
  end
end
