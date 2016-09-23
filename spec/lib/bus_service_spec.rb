# frozen_string_literal: true
require 'spec_helper'
require 'bus_service'

RSpec.describe BusService do
  describe '#status' do
    let(:train_service) { BusService.new('Reading', 'Guildford') }

    before do
      train_service.scheduled_departure = '10:00'
    end

    context 'when cancelled' do
      before { train_service.estimated_departure = 'cancelled' }
      it 'returns the cancelled text' do
        expect(train_service.status).to eql(
          'BUS SERVICE: The 10:00 Reading to Guildford has been cancelled'
        )
      end
    end

    context 'when delayed' do
      before { train_service.estimated_departure = 'delayed' }
      it 'returns the delayed text' do
        expect(train_service.status).to eql(
          'BUS SERVICE: The 10:00 Reading to Guildford has been delayed'
        )
      end
    end

    context 'when on time' do
      before { train_service.estimated_departure = 'on time' }
      it 'returns the on time text' do
        expect(train_service.status).to eql(
          'BUS SERVICE: The 10:00 Reading to Guildford is on time'
        )
      end
    end

    # rubocop:disable Metrics/LineLength
    context 'when not cancelled, delayed or on time' do
      before { train_service.estimated_departure = '10:23' }
      it 'returns the default text' do
        expect(train_service.status).to eql(
          'BUS SERVICE: The 10:00 Reading to Guildford is expected to depart at 10:23'
        )
      end
    end
    # rubocop:enable Metrics/LineLength
  end
end
