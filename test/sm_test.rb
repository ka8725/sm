require 'minitest/autorun'
require 'test_helper'

class MovementState
  include StateMachine

  state :standing, initial: true
  state :walking
end

def define_state_machine(&def_dsl)
  Class.new do
    include StateMachine

    instance_eval(&def_dsl)
  end
end

describe StateMachine do
  describe 'DSL' do
    def error_message_on_dsl_definition(&def_dsl)
      message = nil
      begin
        define_state_machine(&def_dsl)
      rescue => e
        message = e.message
      end

      message
    end

    describe '.state' do
      it 'does not allow to define initial state twice' do
        assert_equal('Initial state is already set to standing',
          error_message_on_dsl_definition do
            state :standing, initial: true
            state :walking, initial: true
          end)
      end

      it 'does not allow to define the same state twice' do
        assert_equal('State :standing is already defined',
          error_message_on_dsl_definition do
            state :standing
            state :standing
          end)
      end

      it 'does not allow to define state with strings' do
        assert_equal('State must be a Symbol. Given String: standing',
          error_message_on_dsl_definition do
            state 'standing'
          end)
      end

      it 'defines predicates' do
        sm = MovementState.new(:walking)
        refute sm.standing?
        assert sm.walking?
      end
    end

    describe '.event' do
      it 'defines event with block' do
        assert_nil(error_message_on_dsl_definition do
          event :walk do
          end
        end)
      end

      it 'defines null event' do
        assert_nil(error_message_on_dsl_definition do
          event :walk
        end)
      end

      it 'event must be defined with symbol only' do
        assert_equal('Event name must be a Symbol. Given String: walk',
          error_message_on_dsl_definition do
            event 'walk'
          end)
      end

      it 'allows to define transitions' do
        assert_nil(error_message_on_dsl_definition do
          state :standing
          state :walking
          state :running

          event :walk do
            transitions from: :standing, to: :walking
          end

          event :run do
            transitions from: [:standing, :walking], to: :running
          end
        end)
      end

      it 'does not allow to define transitions for not defined states' do
        assert_equal('State :standing is undefined',
          error_message_on_dsl_definition do
            event :event do
              transitions from: :standing, to: :walking
            end
          end)

        assert_equal('State :walking is undefined',
          error_message_on_dsl_definition do
            state :standing

            event :event do
              transitions from: :standing, to: :walking
            end
          end)
      end

      it 'does not allow to define invalid transitions' do
        assert_equal('Transition :standing -> :standing is invalid',
          error_message_on_dsl_definition do
            state :standing

            event :event do
              transitions from: :standing, to: :standing
            end
          end)
      end

      it 'does not allow to define the same transition twice' do
        assert_equal('Transition is already defined :standing -> :walking',
          error_message_on_dsl_definition do
            state :standing
            state :walking

            event :event do
              transitions from: :standing, to: :walking
              transitions from: :standing, to: :walking
            end
          end)
      end

      it 'defines events' do
        machine = define_state_machine do
          state :standing
          state :walking

          event :walk do
            transitions from: :standing, to: :walking
          end
        end.new(:standing)

        assert_equal :standing, machine.state
        machine.walk!
        assert_equal :walking, machine.state
      end

      it 'defines predicates' do
        machine = define_state_machine do
          state :standing
          state :walking
          state :running

          event :walk do
            transitions from: [:standing, :running], to: :walking
          end
        end

        assert_equal true, machine.new(:standing).can_walk?
        assert_equal true, machine.new(:running).can_walk?
        assert_equal false, machine.new(:walking).can_walk?
      end

      it 'allows to define guard clauses with lambda' do
        machine = define_state_machine do
          attr_accessor :weather

          state :standing
          state :walking

          event :walk do
            transitions from: :standing, to: :walking, when: -> (_) { weather == 'good' }
          end
        end.new(:standing)

        machine.weather = 'bad'
        assert_equal false, machine.can_walk?

        machine.weather = 'good'
        assert_equal true, machine.can_walk?
      end

      it 'allows to define guard clauses with symbol' do
        machine = define_state_machine do
          state :standing
          state :walking

          event :walk do
            transitions from: :standing, to: :walking, when: :good_weather?
          end
        end.new(:standing)

        machine.define_singleton_method(:good_weather?) { false }
        assert_equal false, machine.can_walk?

        machine.define_singleton_method(:good_weather?) { true }
        assert_equal true, machine.can_walk?
      end

      it 'allows to define callbacks' do
        machine = define_state_machine do
          attr_accessor :performed_transition

          state :standing
          state :walking

          event :walk do
            transitions from: :standing, to: :walking
          end
        end.new(:standing)

        machine.define_singleton_method(:state_changed) do |event, from, to|
          self.performed_transition = "#{event}: :#{from} -> :#{to}"
        end

        assert_nil machine.performed_transition
        machine.walk!
        assert_equal 'walk: :standing -> :walking', machine.performed_transition
      end
    end
  end

  describe '#new' do
    it 'allows to assigns initial state manually' do
      assert_equal :standing, MovementState.new.state
    end

    it 'should set initial state set to statically defined one' do
      assert_equal :walking, MovementState.new(:walking).state
    end

    it 'does not allow to have state machine with nil state' do
      error = assert_raises ArgumentError do
        define_state_machine do
          event :standing
        end.new
      end

      assert_equal 'State must be a Symbol. Given NilClass: ', error.message
    end
  end
end

