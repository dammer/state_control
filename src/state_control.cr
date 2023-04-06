require "json"
require "./state_control/router.cr"
require "./state_control/save_history.cr"

# TODO: Write documentation for `StateControl`

class StateControl(T)
  VERSION = "0.1.0"

  macro inherited
    extend Router(T)

    @@routes = Set(Tuple(T, T)).new

    def self.routes : Set(Tuple(T, T))
      @@routes.dup
    end

    def routes : Set(Tuple(T, T))
      self.class.routes
    end
  end

  def initialize(initial : T? = nil)
    initial ||= T.new(0)
    @state = Atomic(T).new(initial)
    on_initialize(initial)
  end

  def state : T
    @state.get
  end

  def can?(dest : T, current : T = state)
    self.class.route?(current, dest)
  end

  def go(dest : T, current : T = state)
    return false unless can?(dest, current)
    transite_to(current, dest)
  end

  def possible_routes(current = state)
    self.class.possible_from(current)
  end

  def final_state?
    possible_routes.size.zero?
  end

  def to_json(json : JSON::Builder) : Nil
    state.to_json(json)
  end

  def self.new(pull : ::JSON::PullParser)
    new(T.new(pull))
  end

  protected def on_initialize(initial)
  end

  protected def on_success(prev, current)
  end

  private def transite_to(src : T, dest : T)
    prev, succ = @state.compare_and_set(src, dest)
    if succ
      on_success(prev, dest)
      # run_callbacks_on(prev, dest)
    end
    succ
  end
end
