# frozen_string_literal: true
require_relative 'train_service'

class BusService < TrainService
  private

  def default_text
    "BUS SERVICE: The #{scheduled_departure} #{from_station} to #{to_station}"
  end
end
