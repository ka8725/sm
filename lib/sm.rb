require 'sm/version'
require 'set'

module StateMachine
  Transition = Struct.new(:from, :to)

  class Event
    def initialize(name, state_machine, &block)
      @name = name
      @state_machine = state_machine
      instance_eval(&block) if block
    end

    def execute(target)
      @state_machine.state_must_be_defined!(target.state)
      target.set_state(find_transition!(target.state).to)
    end

    def transitions(from:, to:)
      Array(from).each { |from_state| add_transition(from_state, to) }
    end

    private

    # TODO: optimize search with hash table store
    def find_transition!(from)
      transitions_store.find { |tr| tr.from == from }
    end

    def add_transition(from, to)
      transition_is_not_defined!(from, to)
      transition_is_valid!(from, to)

      transitions_store.push(Transition.new(from, to))
    end

    def transitions_store
      @transitions_store ||= []
    end

    def transition_is_valid!(from, to)
      @state_machine.state_must_be_defined!(from)
      @state_machine.state_must_be_defined!(to)

      return if from != to

      fail ArgumentError, "Transition :#{from} -> :#{to} is invalid"
    end

    # TODO: optimize search with hash table store
    def transition_is_not_defined!(from, to)
      transitions_store.each do |transition|
        next  if transition.from != from || transition.to != to
        fail ArgumentError, "Transition is already defined :#{from} -> :#{to}"
      end
    end
  end

  module StateDefinition
    attr_accessor :initial_state

    def state(name, initial: false)
      state_value_must_be_safe!(name)
      add_state(name)
      assign_initial_state(name) if initial
    end

    def defined_state?(name)
      states.include?(name)
    end

    def state_value_must_be_safe!(name)
      return if name.is_a?(Symbol)

      fail ArgumentError, "State must be a Symbol. Given #{name.class}: #{name}"
    end

    def state_must_be_defined!(name)
      return if states.include?(name)

      fail ArgumentError, "State :#{name} is undefined"
    end

    private

    def add_state(name)
      state_must_not_be_defined!(name)

      define_predicate(name)
      states.add(name)
    end

    def define_predicate(name)
      define_method("#{name}?") do
        state == name
      end
    end

    def states
      @states ||= Set.new
    end

    def assign_initial_state(name)
      initial_state_must_not_be_set!

      self.initial_state = name
    end

    def initial_state_must_not_be_set!
      return unless initial_state

      fail ArgumentError, "Initial state is already set to #{initial_state}"
    end

    def state_must_not_be_defined!(name)
      return unless states.include?(name)

      fail ArgumentError, "State :#{name} is already defined"
    end
  end

  module EventDefinition
    def event(name, &block)
      event_name_must_be_safe!(name)
      add_event(name, &block)
    end

    private

    def events
      @events ||= Set.new
    end

    def add_event(name, &block)
      event = Event.new(name, self, &block)
      events.add(event)

      define_method("#{name}!") do
        event.execute(self)
      end
    end

    def event_name_must_be_safe!(name)
      return if name.is_a?(Symbol)

      fail ArgumentError, "Event name must be a Symbol. Given #{name.class}: #{name}"
    end

  end

  def self.included(base)
    base.extend(StateDefinition)
    base.extend(EventDefinition)
  end

  attr_reader :state

  def initialize(initial_state = nil)
    @state = set_state(initial_state || statically_defined_initial_state)
  end

  def set_state(name)
    state_value_must_be_safe!(name)
    state_must_be_defined!(name)

    @state = name
  end

  private

  def state_value_must_be_safe!(name)
    self.class.state_value_must_be_safe!(name)
  end

  def state_must_be_defined!(name)
    self.class.state_must_be_defined!(name)
  end

  def statically_defined_initial_state
    self.class.initial_state
  end
end
