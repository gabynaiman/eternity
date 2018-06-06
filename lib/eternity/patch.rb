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

      def base_history
        @base_history ||= [base_commit] + base_commit.history
      end

      def current_history
        @current_history ||= [current_commit] + current_commit.history - base_history
      end

      def target_history
        @target_history ||= [target_commit] + target_commit.history - base_history
      end

      def remaining_history
        @remaining_history ||= current_history - target_history
      end

      private

      def calculate_delta
        base_commit.with_index do |base_index|
          current_commit.with_index do |current_index|

            current_delta = Delta.merge current_history.reverse.map(&:delta)
            target_delta = Delta.merge target_history.reverse.map(&:delta)
            revert_delta = Delta.revert current_delta, base_index

            merged_delta = merge_deltas target_delta, revert_delta, base_index

            merged_delta.each_with_object({}) do |(collection, elements), hash|
              hash[collection] = {}

              elements.each do |id, change|
                if change['action'] == UPDATE && current_index[collection][id].sha1 == Blob.digest(Blob.serialize(change['data']))
                  change = nil 
                elsif change['action'] == DELETE && !current_index[collection].include?(id)
                  change = nil
                end
                hash[collection][id] = change if change
              end

              hash.delete collection if hash[collection].empty?
            end
          end
        end
      end

    end


    class Merge
      
      include Common

      def merged?
        @merged ||= current_commit == target_commit ||
                    target_commit.fast_forward?(current_commit) || 
                    current_commit.fast_forward?(target_commit)
      end

      private

      def calculate_delta
        return {} if merged?
        super
      end

      def merge_deltas(target_delta, revert_delta, base_index)
        remaining_delta = Delta.merge remaining_history.reverse.map(&:delta)
        Delta.merge [revert_delta, target_delta, remaining_delta], base_index
      end

    end


    class Diff

      include Common

      private

      def merge_deltas(target_delta, revert_delta, base_index)
        Delta.merge [revert_delta, target_delta], base_index
      end

    end

  end
end
