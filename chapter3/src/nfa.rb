require 'set'

class FARule < Struct.new(:state, :character, :next_state)
    def applies_to?(state, character)
        self.state == state && self.character == character
    end

    def follow
        next_state
    end

    def inspect
        "#<FARule # {state.inspect} --# {character} --> #{next_state.inspect}>"
    end
end


class NFARulebook < Struct.new(:rules)
    def next_states(states, character)
        states.map { |state| follow_rurles_for(state, character) }.flatten(1).to_set
    end

    def follow_rurles_for(state, character)
        rules_for(state, character).map(&:follow)
    end

    def rules_for(state, character)
        rules.select { |rule| rule.applies_to?(state, character) }
    end

    def follow_free_moves(states)
        more_states = next_states(states, nil)

        if more_states.subset?(states)
            states
        else
            follow_free_moves(states + more_states)
        end
    end

    def alphabet
        rules.map(&:character).compact.uniq
    end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
    def accepting?
        (current_states & accept_states).any?
    end

    def read_character(character)
        self.current_states = rulebook.next_states(current_states, character)
    end

    def read_string(string)
        string.chars.each do |character|
            read_character(character)
        end
    end

    def current_states
        rulebook.follow_free_moves(super)
    end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
    def accepts?(string)
        to_nfa.tap{ |nfa| nfa.read_string(string) }.accepting?
    end

    def to_nfa(current_states = Set[start_state])
        NFA.new(current_states, accept_states, rulebook)
    end
end

class NFASimulation < Struct.new(:nfa_design)
    def next_state(state, character)
        nfa_design.to_nfa(state).tap { |nfa|
            nfa.read_character(character)
        }.current_states
    end

    def rules_for(state)
        nfa_design.rulebook.alphabet.map { |character|
            FARule.new(state, character, next_state(state, character))
        }
    end

    def discover_states_and_rules(states)
        rules = states.map { |state| rules_for(state) }.flatten(1)
        more_states = rules.map(&:follow).to_set

        if more_states.subset?(states)
            [states, rules]
        else
            discover_states_and_rules(states + more_states)
        end
    end
end
