# frozen_string_literal: true
require 'net/http'
require 'nokogiri'
require_relative 'train_service'
require_relative 'bus_service'

class NationalRailRequest
  attr_accessor :from_station_code, :to_station_code,
                :from_station, :to_station,
                :train_time

  attr_reader :matched_service

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
    Net::HTTP.new(uri.host).request(request)
  end

  def response_body
    response.body
  end

  def xml_response
    raise "401 - Unauthorized #{national_rail_token}" if response.code == '401'
    Nokogiri::XML(response_body)
  end

  def nodes
    xml_response.xpath('//soap:Envelope')
                .children.first.children.first.children.first.children
  end

  def parse_response
    nodes.each do |node|
      next unless initialize_matched_service(node)
      node.children.each do |service_node|
        parse_service_node(service_node)
        break if found_service?
      end
      break if found_service?
    end
    matched_service if found_service?
  end

  def initialize_matched_service(node)
    @matched_service = if node.name == 'trainServices'
                         TrainService.new(from_station, to_station)
                       elsif node.name == 'busServices'
                         BusService.new(from_station, to_station)
                       end
  end

  def found_service?
    matched_service && matched_service.scheduled_departure == train_time
  end

  def parse_service_node(service_node)
    service_node.children.each do |child_node|
      parse_child_node(child_node)
    end
  end

  def parse_child_node(node)
    case node.name
    when 'origin'
      update_service_origin(node)
    when 'destination'
      update_service_destination(node)
    when 'std'
      matched_service.scheduled_departure = node.content
    when 'etd'
      matched_service.estimated_departure = node.content
    when 'platform'
      matched_service.platform = node.content
    end
  end

  def update_service_origin(node)
    node.children.first.children.each do |child_node|
      next unless child_node.name == 'locationName'
      matched_service.origin = child_node.content
    end
  end

  def update_service_destination(node)
    node.children.first.children.each do |child_node|
      if child_node.name == 'locationName'
        matched_service.final_destination = child_node.content
      end
    end
  end
end
