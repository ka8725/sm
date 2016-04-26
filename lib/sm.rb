require 'sm/version'
require 'set'

module StateMachine
  def self.included(base)
    class << base
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
  end

  attr_reader :state

  def initialize(initial_state = nil)
    @state = set_state(initial_state || statically_defined_initial_state)
  end

  private

  def set_state(name)
    state_value_must_be_safe!(name)
    state_must_be_defined!(name)

    @state = name
  end

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
