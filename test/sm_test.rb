require 'minitest/autorun'
require 'test_helper'

class MovementState
  include StateMachine

  state :standing, initial: true
  state :walking
end

describe StateMachine do
  describe 'DSL' do
    def error_message_on_state_definition(&def_dsl)
      message = nil
      begin
        Class.new do
          include StateMachine

          instance_eval(&def_dsl)
        end
      rescue => e
        message = e.message
      end

      message
    end

    describe '.state' do
      it 'does not allow to define initial state twice' do
        assert_equal('Initial state is already set to standing',
          error_message_on_state_definition do
            state :standing, initial: true
            state :walking, initial: true
          end)
      end

      it 'does not allow to define the same state twice' do
        assert_equal('State :standing is already defined',
          error_message_on_state_definition do
            state :standing
            state :standing
          end)
      end

      it 'does not allow to define state with strings' do
        assert_equal('State must be a Symbol. Given String: standing',
          error_message_on_state_definition do
            state 'standing'
          end)
      end

      it 'defines predicates' do
        sm = MovementState.new(:walking)
        refute sm.standing?
        assert sm.walking?
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
  end
end

