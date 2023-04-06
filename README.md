# StateControl

This shard provides a flexible state machine implementation in [Crystal](https://crystal-lang.org) programming language.

You can use any enum to describe different states and use the StateControl(T) class with that enum to create your own specific state machine class.

The StateControl(T) class allows you to manage transitions between states, track transition history, and monitor time spent in each state. By using this shard, you have the flexibility to define and use your own enums and state machine classes tailored to your specific needs.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     state_control:
       github: dammer/state_control
   ```

2. Run `shards install`

## Usage

```crystal
require "state_control"

# define an enum that describes states
enum TestStatus
  Yellow
  Red
  Green
  BlinkGreen
end

# define the state_control class
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

  # кeyword `any` can be used to define multiple routes
  route_enable any: :yellow
  # this is the same as:
  # route_enable red: :yellow
  # route_enable green: :yellow
  # route_enable blinkgreen: :yellow

  # disable unnecessary routes
  route_disable green: :yellow
  route_disable blinkgreen: :yellow

  # draw routes table (optional, debug)
  inspect_routes
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

  # custom handler on success transition by the route (optional)
  protected def on_success(prev, current)
    # `super` call is required if `on_succes` defined for compatibility  
    super
    # do something here
    puts "transited from: #{prev} to: #{current}"
    # or or something useful ;)
    # emit StateChangedEvent, self, prev, current, async: true 
  end
end

# create a state_conrtol instance
state_control = Specs::TestStatusControl.new(:yellow)

# check the current state
state_control.state.yellow?   # => true
state_control.state           # => TestStatus::Yellow

# check if transite to a route is possible
state_control.can?(:red)      # => false
state_control.can?(:green)    # => true

# get all possible routes from the current state
state_control.possible_routes # => [TestStatus::Green]

# transition (bad)
state_control.go(:red)        # => false
state_control.state.red?      # => false

# transition (good)
state_control.go(:green)      # => true
state_control.state.green?    # => true

# check if no routes from current state
state_control.final_state?    # => false

# move through states
i = 0
while dest = state_control.possible_routes.first?
  sleep(i += 1)
  state_control.go(dest)
  break if state_control.state.green?
end

# inspect time line
state_control.inspect_timeline
# ┌───┬────────────┬────────────────────────────────┬────────────────────┐
# │ # │   State    │              Time              │       Spent        │
# ├───┼────────────┼────────────────────────────────┼────────────────────┤
# │ 0 │ BlinkGreen │ 2023-04-06T16:23:21.961333359Z │ 00:00:02.002182295 │
# ├───┼────────────┼────────────────────────────────┼────────────────────┤
# │ 1 │    Red     │ 2023-04-06T16:23:23.963515654Z │ 00:00:02.998190151 │
# ├───┼────────────┼────────────────────────────────┼────────────────────┤
# │ 2 │   Yellow   │ 2023-04-06T16:23:26.961705805Z │ 00:00:04.004193440 │
# ├───┼────────────┼────────────────────────────────┼────────────────────┤
# │ 3 │   Green    │ 2023-04-06T16:23:30.965899245Z │         ∞          │
# └───┴────────────┴────────────────────────────────┴────────────────────┘

# JSON::Serializable compatible
requie "json"

struct JsonTest
  include JSON::Serializable

  getter test_name : String
  getter state_control : TestStatusControl

  def initialize(@test_name, @state_control = TestStatusControl.new)
  end
end

# serialization
json_test = JsonTest.new("json_1")
json_test.state_control.go(:red) # => false                                                
string = json_test.to_json
string.should eq %q<{"test_name":"json_1","state_control":"yellow"}>   

# deserialization
json_test = JsonTest.from_json(string)
json_test.state_control.state.yellow?.should be_true

```

## Development

During the development process, we follow best practices to ensure code quality and maintainability. Here are some guidelines:

- All code changes should be reviewed by the team to maintain consistency and quality.
- Code should pass the [Ameba](https://github.com/veelenga/ameba) linter and be formatted with [Crystal Tool Format](https://crystal-lang.org/docs/conventions/coding_style.html).
- Functionality introduced in pull requests should be accompanied by appropriate spec tests to ensure proper functionality and prevent regressions.
- Commits should have clear and descriptive commit messages following [conventional commit messages](https://www.conventionalcommits.org/en/v1.0.0/).
- Branches should be created based on the [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) branching model, with meaningful names that reflect the feature or fix being implemented.
- Pull requests should be submitted to the designated branch for review and merged only after approval from the team.

We appreciate your contribution to the project and adherence to these development guidelines, which help us maintain high code quality and ensure a smooth development process.

## Contributing

1. Fork it (<https://github.com/your-github-user/state_control/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Acknowledgements

I would like to acknowledge the following sources and tools that have been instrumental in the creation of this project:

- [Crystal](https://crystal-lang.org) programming language: for providing a flexible and powerful language for developing this state machine implementation.
- OpenAI's ChatGPT (GPT-3.5 model): for providing valuable insights and assistance in generating this README.

## Contributors

- [Damir Sharipov](https://github.com/your-github-user) - creator and maintainer
