# frozen_string_literal: true
require 'spec_helper'
require 'national_rail_request'

RSpec.describe NationalRailRequest do
  let(:options) do
    {
      'from_station_code': 'RDG',
      'to_station_code': 'WKM',
      'from_station': 'Reading',
      'to_station': 'Wokingham',
      'train_time': '23:52'
    }
  end

  before do
    Dotenv.load("#{File.expand_path(Dir.pwd)}/.env.test")
  end

  describe '::check_service' do
    it 'generates a new instance with the options and calls check_service' do
      allow(NationalRailRequest).to receive(:new).with(options).and_return(
        double('instance', check_service: :return_value)
      )
      expect(NationalRailRequest.check_service(options)).to eql(:return_value)
    end
  end

  describe '#check_service' do
    let(:request) { NationalRailRequest.new(options) }

    # rubocop:disable Metrics/LineLength
    let(:xml_string) do
      "<SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ns1='http://thalesgroup.com/RTTI/2014-02-20/ldb/' xmlns:ns2='http://thalesgroup.com/RTTI/2010-11-01/ldb/commontypes'>" \
        '<SOAP-ENV:Header>' \
          '<ns2:AccessToken>' \
            '<ns2:TokenValue>NationalRailToken</ns2:TokenValue>' \
          '</ns2:AccessToken>' \
        '</SOAP-ENV:Header>' \
        '<SOAP-ENV:Body>' \
          '<ns1:GetDepartureBoardRequest>' \
            '<ns1:numRows>10</ns1:numRows>' \
            '<ns1:crs>RDG</ns1:crs>' \
            '<ns1:filterCrs>WKM</ns1:filterCrs>' \
          '</ns1:GetDepartureBoardRequest>' \
        '</SOAP-ENV:Body>' \
      '</SOAP-ENV:Envelope>'
    end
    # rubocop:enable Metrics/LineLength

    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Type' => 'text/xml',
        'User-Agent' => 'Ruby'
      }
    end

    context 'when a train service is running' do
      let(:response) do
        File.read(
          File.expand_path('../../fixtures/train.xml', __FILE__)
        )
      end

      before do
        stub_request(
          :post, 'http://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb6.asmx'
        )
          .with(body: xml_string, headers: headers)
          .to_return(
            status: 200,
            body: response,
            headers: {}
          )
      end

      let(:service) { request.check_service }

      it 'forms the request body correctly' do
        expect(request.send(:xml_string)).to eql(xml_string)
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

      before do
        stub_request(
          :post, 'http://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb6.asmx'
        )
          .with(body: xml_string, headers: headers)
          .to_return(
            status: 200,
            body: response,
            headers: {}
          )
      end

      let(:service) { request.check_service }

      it 'forms the request body correctly' do
        expect(request.send(:xml_string)).to eql(xml_string)
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
