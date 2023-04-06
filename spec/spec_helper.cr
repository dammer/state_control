require "spec"
require "../src/state_control"

module Specs
  enum TestStatus
    Yellow
    Red
    Green
    BlinkGreen
  end

  class TestStatusControl < StateControl(TestStatus)
    # enable state transitions history tracking (optional)
    include SaveHistory
    # set history size limit
    maximum_history_size 4

    # enable routes
    route_enable red: :yellow
    route_enable yellow: :green
    route_enable green: :blink_green
    route_enable blink_green: :red

    # keyword `any` can be used for define multiple routes
    route_enable any: :yellow
    # this is same as:
    # route_enable red: :yellow
    # route_enable green: :yellow
    # route_enable blinkgreen: :yellow

    # disable unnecessary routes
    route_disable green: :yellow
    route_disable blinkgreen: :yellow

    # draw routes table (optional, debug)
    # ┌────────────┬────────────┬────────────┬────────────┬────────────┐
    # │     ->     │   Yellow   │    Red     │   Green    │ BlinkGreen │
    # ├────────────┼────────────┼────────────┼────────────┼────────────┤
    # │   Yellow   │            │            │     X      │            │
    # ├────────────┼────────────┼────────────┼────────────┼────────────┤
    # │    Red     │     X      │            │            │            │
    # ├────────────┼────────────┼────────────┼────────────┼────────────┤
    # │   Green    │            │            │            │     X      │
    # ├────────────┼────────────┼────────────┼────────────┼────────────┤
    # │ BlinkGreen │            │     X      │            │            │
    # └────────────┴────────────┴────────────┴────────────┴────────────┘
    inspect_routes

    # custom handler on success transition by the route (optional)
    protected def on_success(prev, current)
      super
      # puts "transited from: #{prev} to: #{current}"
    end
  end

  struct JsonTest
    include JSON::Serializable

    getter test_name : String
    getter state_control : TestStatusControl

    def initialize(@test_name, @state_control = TestStatusControl.new)
    end
  end
end
