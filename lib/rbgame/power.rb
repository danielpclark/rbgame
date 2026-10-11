# frozen_string_literal: true

module Rbgame
  # The machine's power supply, for games that dim effects or save more often
  # on battery. On Linux SDL asks UPower, then /sys/class/power_supply,
  # /proc/acpi and /proc/apm; on Windows the system power status.
  #
  #   Power.status            # => Status(state: :on_battery, seconds_left: 5400, percent: 72)
  #   Power.on_battery?       # => true
  #   Power.status.low?       # => false (below 20% by default)
  module Power
    STATES = %i[error unknown on_battery no_battery charging charged].freeze
    PLUGGED_IN = %i[no_battery charging charged].freeze

    # One look at the supply. `seconds_left` and `percent` are nil when the
    # platform cannot say (and always on mains power).
    Status = Data.define(:state, :seconds_left, :percent) do
      def on_battery? = state == :on_battery
      def plugged_in? = PLUGGED_IN.include?(state)
      def charging? = state == :charging
      def charged? = state == :charged
      def battery? = %i[on_battery charging charged].include?(state)
      def known? = !%i[error unknown].include?(state)

      # Running low on battery: below `below` (0 to 1) when the percent is known.
      def low?(below: 0.2) = on_battery? && !percent.nil? && percent < below * 100

      # Battery life left, or nil.
      def time_left = seconds_left&.to_f
      def to_s = percent ? "#{state} #{percent}%" : state.to_s
    end

    class << self
      def status
        state, seconds, percent = Native.power_info
        Status.new(state: state.to_sym, seconds_left: seconds, percent: percent)
      end

      def state = status.state
      def percent = status.percent
      def on_battery? = status.on_battery?
      def plugged_in? = status.plugged_in?
    end
  end
end
