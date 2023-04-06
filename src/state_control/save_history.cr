module StateControl::SaveHistory
  macro included
    @transitions = Array(T).new
    @timeline = Array(Time).new

    @@maximum_history_size : Int32 = 0

    def self.maximum_history_size(size : Int32)
      @@maximum_history_size = size
    end
  end

  def history
    @transitions.dup
  end

  def timeline
    @transitions.zip(timeline_to_state_durations)
  end

  # draw table with time enter to state and spent in each state
  # ┌───┬────────────┬────────────────────────────────┬────────────────────┐
  # │ # │   State    │              Time              │       Spent        │
  # ├───┼────────────┼────────────────────────────────┼────────────────────┤
  # │ 0 │   Yellow   │ YYYY-MM-DDT10:13:02.254106929Z │ 00:00:00.000008061 │
  # ├───┼────────────┼────────────────────────────────┼────────────────────┤
  # │ 1 │   Green    │ YYYY-MM-DDT10:13:02.254114990Z │ 00:00:00.000010891 │
  # ├───┼────────────┼────────────────────────────────┼────────────────────┤
  # │ 2 │ BlinkGreen │ YYYY-MM-DDT10:13:02.254125881Z │ 00:00:00.000005914 │
  # ├───┼────────────┼────────────────────────────────┼────────────────────┤
  # │ 3 │    Red     │ YYYY-MM-DDT10:13:02.254131795Z │         ∞          │
  # └───┴────────────┴────────────────────────────────┴────────────────────┘
  def inspect_timeline(io = STDOUT)
    table = Table.new(%w{# State Time Spent})
    timeline.each_with_index do |(state, duration), idx|
      duration_text = duration.infinite? ? "∞" : duration.seconds.to_s
      time_text = @timeline[idx].to_rfc3339(fraction_digits: 9)
      table.add_row([idx.to_s, state.to_s, time_text, duration_text])
    end
    io << "\n"
    table.render(io, adjust_width: :personal)
  end

  protected def on_initialize(initial)
    super
    history_add(initial)
  end

  protected def on_success(prev, current)
    super
    history_add(current)
  end

  private def history_add(current, time = Time.utc)
    @transitions.push(current)
    @timeline.push(time)
    check_history_size
  end

  private def check_history_size
    return unless @@maximum_history_size.positive?
    return unless @transitions.size > @@maximum_history_size
    @transitions = @transitions.last(@@maximum_history_size)
    @timeline = @timeline.last(@@maximum_history_size)
  end

  private def timeline_to_state_durations
    @timeline.each_cons_pair
      .map { |a, b| (b - a).to_f }
      .to_a
      .push(Float64::INFINITY)
  end
end
