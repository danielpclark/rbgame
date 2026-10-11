# frozen_string_literal: true

require "test_helper"

# Whatever this machine's supply is, the answer is one of SDL's states with
# consistent predicates; a CI runner usually has no battery or cannot say.
class PowerTest < Minitest::Test
  Power = Rbgame::Power

  def test_status_is_one_of_sdls_states
    status = Power.status
    assert_includes Power::STATES, status.state
    assert_equal status.state, Power.state
    assert status.percent.nil? || status.percent.between?(0, 100)
    assert status.seconds_left.nil? || status.seconds_left >= 0
    assert_equal status.on_battery?, Power.on_battery?
    assert_equal status.plugged_in?, Power.plugged_in?
    refute(status.on_battery? && status.plugged_in?, "cannot be both")
    assert_equal status.battery? || status.state == :no_battery, status.known?
  end

  def test_predicates_read_a_status
    low = Power::Status.new(state: :on_battery, seconds_left: 600, percent: 12)
    assert low.on_battery?
    assert low.battery?
    assert low.low?
    refute low.low?(below: 0.1)
    refute low.plugged_in?
    assert_in_delta 600.0, low.time_left
    assert_equal "on_battery 12%", low.to_s

    mains = Power::Status.new(state: :no_battery, seconds_left: nil, percent: nil)
    assert mains.plugged_in?
    refute mains.battery?
    refute mains.low?
    assert_nil mains.time_left
    assert_equal "no_battery", mains.to_s

    charging = Power::Status.new(state: :charging, seconds_left: nil, percent: 50)
    assert charging.charging?
    assert charging.plugged_in?
    assert charging.battery?
    refute charging.low?

    refute Power::Status.new(state: :unknown, seconds_left: nil, percent: nil).known?
  end
end
