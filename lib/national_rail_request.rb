# frozen_string_literal: true
require 'net/http'
require_relative 'national_rail_request_parser'

# Generates the Request to discover if a service is running
class NationalRailRequest
  attr_accessor :from_station_code, :to_station_code,
                :from_station, :to_station,
                :train_time

  def self.check_service(options)
    new(options).check_service
  end

  def initialize(options)
    options.each do |key, val|
      send("#{key}=", val)
    end
  end

  def check_service
    parse_response
  end

  private

  def national_rail_token
    @national_rail_token ||= ENV['NATIONAL_RAIL_TOKEN']
  end

  def uri
    URI.parse('https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb6.asmx')
  end

  def request
    @request ||= Net::HTTP::Post.new(uri.path).tap do |request|
      request.content_type = 'text/xml'
      request.body = xml_string
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  def xml_string
    "<SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ns1='http://thalesgroup.com/RTTI/2014-02-20/ldb/' xmlns:ns2='http://thalesgroup.com/RTTI/2010-11-01/ldb/commontypes'>" \
      '<SOAP-ENV:Header>' \
        '<ns2:AccessToken>' \
          "<ns2:TokenValue>#{national_rail_token}</ns2:TokenValue>" \
        '</ns2:AccessToken>' \
      '</SOAP-ENV:Header>' \
      '<SOAP-ENV:Body>' \
        '<ns1:GetDepartureBoardRequest>' \
          '<ns1:numRows>10</ns1:numRows>' \
          "<ns1:crs>#{from_station_code}</ns1:crs>" \
          "<ns1:filterCrs>#{to_station_code}</ns1:filterCrs>" \
        '</ns1:GetDepartureBoardRequest>' \
      '</SOAP-ENV:Body>' \
    '</SOAP-ENV:Envelope>'
  end
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/MethodLength

  def response
    @response ||= Net::HTTP.new(uri.host).request(request)
  end

  def response_body
    @response_body ||= response.body
  end

  def response_unauthorized?
    @response_unauthorized ||= response.code == '401'
  end

  def parse_response
    raise "401 - Unauthorized #{national_rail_token}" if response_unauthorized?
    NationalRailRequestParser.run(
      response_body: response_body,
      from_station: from_station,
      to_station: to_station,
      train_time: train_time
    )
  end
end
