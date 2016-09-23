# frozen_string_literal: true
require 'spec_helper'
require 'national_rail_notifier'
require 'dotenv'

DummyTweet = Struct.new(:text)

class DummyTwitterClient
  attr_accessor :consumer_key, :consumer_secret, :access_token,
                :access_token_secret

  def user_timeline
    [DummyTweet.new('Foo'), DummyTweet.new('Bar')]
  end
end

RSpec.describe NationalRailNotifier do
  let(:options) do
    {
      'from_station_code': 'RDG',
      'to_station_code': 'WKM',
      'from_station': 'Reading',
      'to_station': 'Wokingham',
      'train_time': '07:23'
    }
  end

  before do
    Dotenv.load("#{File.expand_path(Dir.pwd)}/.env.test")
  end

  describe '::run' do
    it 'generates a new instance with the options and calls run' do
      allow(NationalRailNotifier).to receive(:new).with(options).and_return(
        double('instance', run: :return_value)
      )
      expect(NationalRailNotifier.run(options)).to eql(:return_value)
    end
  end

  describe 'run' do
    let(:notifier) { NationalRailNotifier.new(options) }
    let(:twitter_client) { DummyTwitterClient.new }

    context 'when it is a weekday' do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2016, 9, 21))
        expect(Twitter::REST::Client).to receive(:new) do |&block|
          block.call(twitter_client)
          twitter_client
        end
        expect(NationalRailRequest).to receive(
          :check_service
        ).with(options).and_return(
          double('service', status: 'The Status')
        )
      end
      it 'tweets the service status' do
        expect(twitter_client).to receive(:update).with('The Status')
        notifier.run
        expect(twitter_client.consumer_key).to eql('TwitterKey')
        expect(twitter_client.consumer_secret).to eql(
          'TwitterConsumerSecret'
        )
        expect(twitter_client.access_token).to eql(
          'TwitterAccessToken'
        )
        expect(twitter_client.access_token_secret).to eql(
          'TwitterAccessTokenSecret'
        )
      end
    end

    context 'when it is a weekend' do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2016, 9, 24))
      end
      it 'does not tweet the service status' do
        expect(Twitter::REST::Client).not_to receive(:new)
        notifier.run
      end
    end
  end
end
