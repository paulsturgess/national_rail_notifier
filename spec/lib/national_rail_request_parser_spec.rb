# frozen_string_literal: true
require 'spec_helper'
require 'dotenv'
require 'national_rail_request_parser'

RSpec.describe NationalRailRequestParser do
  let(:options) do
    {
      'from_station': 'Reading',
      'to_station': 'Wokingham',
      'train_time': '23:52'
    }
  end

  before do
    Dotenv.load("#{File.expand_path(Dir.pwd)}/.env.test")
  end

  describe '::run' do
    it 'generates a new instance with the options and calls run' do
      allow(NationalRailRequestParser).to receive(:new)
        .with(options).and_return(
          double('instance', run: :return_value)
        )
      expect(NationalRailRequestParser.run(options)).to eql(:return_value)
    end
  end

  describe '#run' do
    let(:service) do
      NationalRailRequestParser.new(
        options.merge(response_body: response)
      ).run
    end

    context 'when a train service is running' do
      let(:response) do
        File.read(
          File.expand_path('../../fixtures/train.xml', __FILE__)
        )
      end

      it 'returns a TrainService instance' do
        expect(service).to be_a(TrainService)
      end

      it 'sets the service origin' do
        expect(service.origin).to eql('Reading')
      end

      it 'sets the service final_destination' do
        expect(service.final_destination).to eql('Ascot')
      end

      it 'sets the service scheduled_departure' do
        expect(service.scheduled_departure).to eql('23:52')
      end

      it 'sets the service estimated_departure' do
        expect(service.estimated_departure).to eql('On time')
      end

      it 'sets the service platform' do
        expect(service.platform).to eql('1')
      end
    end

    context 'when a bus service is running' do
      let(:response) do
        File.read(
          File.expand_path('../../fixtures/bus.xml', __FILE__)
        )
      end

      it 'returns a TrainService instance' do
        expect(service).to be_a(BusService)
      end

      it 'sets the service origin' do
        expect(service.origin).to eql('Reading')
      end

      it 'sets the service final_destination' do
        expect(service.final_destination).to eql('Ascot')
      end

      it 'sets the service scheduled_departure' do
        expect(service.scheduled_departure).to eql('23:52')
      end

      it 'sets the service estimated_departure' do
        expect(service.estimated_departure).to eql('On time')
      end

      it 'sets the service platform' do
        expect(service.platform).to eql('1')
      end
    end
  end
end
