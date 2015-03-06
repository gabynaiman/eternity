module Eternity
  module Patch

    def self.merge(current_commit, target_commit)
      Merge.new current_commit, target_commit
    end

    def self.diff(current_commit, target_commit)
      Diff.new current_commit, target_commit
    end

    module Common

      attr_reader :current_commit, :target_commit

      def initialize(current_commit, target_commit)
        @current_commit = current_commit
        @target_commit = target_commit
      end

      def base_commit
        @base_commit ||= Commit.base_of current_commit, target_commit
      end

      def delta 
        @delta ||= TransparentProxy.new { calculate_delta }
      end

      private

      def current_delta
        @current_delta ||= base_delta_of current_commit, base_commit
      end

      def target_delta
        @target_delta ||= base_delta_of target_commit, base_commit
      end

      def base_delta_of(commit, base)
        return {} if commit == base
        history = [commit] + commit.base_history_at(base)[0..-2]
        Delta.merge history.reverse.map(&:base_delta)
      end

    end


    class Merge
      
      extend Log
      include Common

      def base_delta
        @base_delta ||= merged? ? {} : Delta.merge([current_delta, delta])
      end

      def merged?
        @merged ||= current_commit == target_commit ||
                    target_commit.fast_forward?(current_commit) || 
                    current_commit.fast_forward?(target_commit)
      end

      private

      def calculate_delta
        return {} if merged?

        base_commit.with_index do |base_index|
          target_delta.each_with_object({}) do |(collection, elements), hash|
            hash[collection] = {}
           
            elements.each do |id, change|
              if change['action'] == INSERT && current_action_for(collection, id) == INSERT
                data = ConflictResolver.resolve current_delta[collection][id]['data'], 
                                                change['data']
                change = {'action' => UPDATE, 'data' => data}
              
              elsif change['action'] == UPDATE
                if current_action_for(collection, id) == UPDATE
                  data = ConflictResolver.resolve current_delta[collection][id]['data'], 
                                                  change['data'], 
                                                  base_index[collection][id].data
                  change = change.merge 'data' => data
                elsif current_action_for(collection, id) == DELETE
                  change = {'action' => INSERT, 'data' => change['data']}
                end
              
              elsif change['action'] == DELETE && current_action_for(collection, id) == DELETE
                change = nil
              end

              hash[collection][id] = change if change
            end

            hash.delete collection if hash[collection].empty?
          end
        end
      end

      def has_current_changes_for?(collection, id)
        current_delta.key?(collection) && current_delta[collection].key?(id)
      end

      def current_action_for(collection, id)
        current_delta[collection][id]['action'] if has_current_changes_for? collection, id
      end

      log :calculate_delta

    end


    class Diff
      
      extend Log
      include Common

      private

      def calculate_delta
        Delta.merge [Delta.revert(current_delta, base_commit), target_delta]
      end

      log :calculate_delta

    end

  end
end
