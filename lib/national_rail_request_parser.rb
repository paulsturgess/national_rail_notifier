# frozen_string_literal: true
require 'nokogiri'
require_relative 'train_service'
require_relative 'bus_service'

# Parses the xml response and returns either a TrainService or BusService
class NationalRailRequestParser
  attr_accessor :response_body, :from_station, :to_station, :train_time
  attr_reader :matched_service

  def self.run(options)
    new(options).run
  end

  def initialize(options)
    options.each do |key, val|
      send("#{key}=", val)
    end
  end

  def run
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

  private

  def xml_response
    @xml_response ||= Nokogiri::XML(response_body)
  end

  def nodes
    xml_response.xpath('//soap:Envelope')
                .children.first.children.first.children.first.children
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
