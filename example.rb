# Run this code with the following command: ruby -I lib example.rb
require 'sm'

class Handler
  def initialize(from, to)
    @from = from
    @to = to
  end

  def call
    fail NotImplementedError
  end
end

class WalkHandler < Handler
  def call
    puts "Walking now. Transition was: #{@from} -> #{@to}"
  end
end

class RunHandler < Handler
  def call
    puts "Running now. Transition was: #{@from} -> #{@to}"
  end
end

class HoldHandler < Handler
  def call
    puts "Standing now. Transition was: #{@from} -> #{@to}"
  end
end

class EventHandlerFactory
  HANDLERS_MAPPING = {
    walk: WalkHandler,
    run: RunHandler,
    hold: HoldHandler
  }

  def self.create(event, old_state, new_state)
    HANDLERS_MAPPING.fetch(event).new(old_state, new_state)
  end
end

class MovementState
  include StateMachine

  state :standing, initial: true
  state :walking
  state :running

  event :walk do
    transitions from: :standing, to: :walking
  end

  event :run do
    transitions from: [:standing, :walking], to: :running
  end

  event :hold do
    transitions from: [:walking, :running], to: :standing
  end

  def state_changed(event, old_state, new_state)
    EventHandlerFactory.create(event, old_state, new_state).call
  end
end

m = MovementState.new
m.walk!
m.run!
m.hold!

m.run!
m.hold!
