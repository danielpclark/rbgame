# frozen_string_literal: true

module Rbgame
  # The event queue.
  #
  #   Events.each { |event| ... }     # everything queued right now
  #   Events.poll                     # one event or nil
  #   Events.wait(timeout: 0.5)       # block for the next one
  #   Events.push_quit
  module Events
    class << self
      include Enumerable

      def poll
        hash = Native.poll_event
        hash && Event.from_hash(hash)
      end

      # Drains the queue, yielding each event; returns an Enumerator without
      # a block.
      def each
        return enum_for(:each) unless block_given?

        while (event = poll)
          yield event
        end
        self
      end

      # Blocks until an event arrives. `timeout` in seconds, nil for forever.
      def wait(timeout: nil)
        hash = Native.wait_event(timeout && (timeout * 1000).round)
        hash && Event.from_hash(hash)
      end

      def pump = Native.pump_events
      def flush = Native.flush_events
      def push_quit = Native.push_quit
      def push_user(code = 0) = Native.push_user_event(code)
      def pending = Native.queued_event_count
    end
  end
end
