require "./spec_helper"

describe StateControl do
  it "set routes when define class" do
    set = [{Specs::TestStatus::Red, Specs::TestStatus::Yellow}, {Specs::TestStatus::Yellow, Specs::TestStatus::Green}, {Specs::TestStatus::Green, Specs::TestStatus::BlinkGreen}, {Specs::TestStatus::BlinkGreen, Specs::TestStatus::Red}].to_set
    Specs::TestStatusControl.routes.should eq set
  end

  it "strict state changes by routes" do
    sc = Specs::TestStatusControl.new
    sc.state.yellow?.should be_true
    sc.history.should eq [Specs::TestStatus::Yellow]
    sc.timeline.should eq [{Specs::TestStatus::Yellow, Float64::INFINITY}]
    sc.possible_routes.should eq [Specs::TestStatus::Green]
    sc.can?(:yellow).should be_false
    sc.go(:yellow).should be_false
    sc.can?(:red).should be_false
    sc.go(:red).should be_false
    sc.can?(:blink_green).should be_false
    sc.go(:blink_green).should be_false

    sc.can?(:green).should be_true
    sc.go(:green).should be_true
    sc.history.should eq [
      Specs::TestStatus::Yellow,
      Specs::TestStatus::Green,
    ]

    sc.timeline.first.tap do |el|
      el.first.should eq(Specs::TestStatus::Yellow)
      el.last.should be > 0
    end
    sc.timeline.last.should eq({Specs::TestStatus::Green, Float64::INFINITY})

    sc.can?(:yellow).should be_false
    sc.go(:yellow).should be_false
    sc.can?(:red).should be_false
    sc.go(:red).should be_false
    sc.can?(:green).should be_false
    sc.go(:green).should be_false

    sc.can?(:blink_green).should be_true
    sc.go(:blink_green).should be_true

    sc.history.should eq [
      Specs::TestStatus::Yellow,
      Specs::TestStatus::Green,
      Specs::TestStatus::BlinkGreen,
    ]
    sc.timeline[-2].tap do |el|
      el.first.should eq(Specs::TestStatus::Green)
      el.last.should be > 0
    end
    sc.timeline.last.should eq({Specs::TestStatus::BlinkGreen, Float64::INFINITY})

    sc.can?(:blink_green).should be_false
    sc.go(:blink_green).should be_false
    sc.can?(:yellow).should be_false
    sc.go(:yellow).should be_false
    sc.can?(:green).should be_false
    sc.go(:green).should be_false

    sc.can?(:red).should be_true
    sc.go(:red).should be_true

    sc.history.should eq [
      Specs::TestStatus::Yellow,
      Specs::TestStatus::Green,
      Specs::TestStatus::BlinkGreen,
      Specs::TestStatus::Red,
    ]

    sc.timeline[-2].tap do |el|
      el.first.should eq(Specs::TestStatus::BlinkGreen)
      el.last.should be > 0
    end
    sc.timeline.last.should eq({Specs::TestStatus::Red, Float64::INFINITY})

    sc.inspect_timeline

    sc.can?(:red).should be_false
    sc.go(:red).should be_false
    sc.can?(:blink_green).should be_false
    sc.go(:blink_green).should be_false
    sc.can?(:green).should be_false
    sc.go(:green).should be_false

    sc.can?(:yellow).should be_true
    sc.go(:yellow).should be_true

    sc.history.should eq [
      # maximum_history_sizie 4
      # Specs::TestStatus::Yellow,
      Specs::TestStatus::Green,
      Specs::TestStatus::BlinkGreen,
      Specs::TestStatus::Red,
      Specs::TestStatus::Yellow,
    ]
    sc.timeline[-2].tap do |el|
      el.first.should eq(Specs::TestStatus::Red)
      el.last.should be > 0
    end
    sc.timeline.last.should eq({Specs::TestStatus::Yellow, Float64::INFINITY})
  end

  it "serializable" do
    s = Specs::JsonTest.new("test_1")
    s.state_control.go(:red)
    s.to_json.should eq %q<{"test_name":"test_1","state_control":"yellow"}>
  end

  it "deserializable" do
    s = Specs::JsonTest.from_json(%q<{"test_name":"test_1","state_control":"yellow"}>)
    s.state_control.state.yellow?.should be_true
  end
end
