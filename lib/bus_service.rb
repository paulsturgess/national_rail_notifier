# frozen_string_literal: true
require_relative 'train_service'

# A wrapper around the bus details returned from the api request
class BusService < TrainService
  private

  def default_text
    "BUS SERVICE: The #{scheduled_departure} #{from_station} to #{to_station}"
  end
end
