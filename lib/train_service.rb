# frozen_string_literal: true

# A wrapper around the train details returned from the api request
class TrainService
  attr_accessor :origin, :final_destination, :scheduled_departure,
                :estimated_departure, :platform, :from_station, :to_station

  def initialize(from_station, to_station)
    self.from_station = from_station
    self.to_station = to_station
  end

  def status
    if on_time?
      "#{default_text} is on time"
    elsif cancelled?
      "#{default_text} has been cancelled"
    elsif delayed?
      "#{default_text} has been delayed"
    else
      "#{default_text} is expected to depart at #{estimated_departure}"
    end
  end

  private

  def default_text
    "The #{scheduled_departure} #{from_station} to #{to_station} train"
  end

  def delayed?
    estimated_departure.casecmp('delayed').zero?
  end

  def on_time?
    estimated_departure.casecmp('on time').zero?
  end

  def cancelled?
    estimated_departure.casecmp('cancelled').zero?
  end
end
