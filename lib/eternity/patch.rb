module Eternity
  class Patch

    attr_reader :current_commit, :target_commit
    
    def initialize(current_commit, target_commit)
      @current_commit = current_commit
      @target_commit = target_commit
    end

    def base_commit
      @base_commit ||= Commit.base_of current_commit, target_commit
    end

    def current_delta
      @current_delta ||= base_delta_of current_commit
    end

    def target_delta
      @target_delta ||= base_delta_of target_commit
    end

    def index_delta 
      @index_delta ||= calculate_index_delta
    end

    def base_delta 
      @base_delta ||= merge [current_delta, index_delta]
    end

    def commits
      [current_commit, target_commit]
    end

    def commit_ids
      commits.map(&:id)
    end

    private

    def base_delta_of(commit)
      return {} if commit == base_commit
      history = [commit] + commit.base_history_at(base_commit)[0..-2]
      merge history.reverse.map(&:base_delta)
    end

    def merge(deltas)
      union(deltas).each_with_object({}) do |(collection, elements), hash|
        hash[collection] = {}
        elements.each do |id, changes|
          hash[collection][id] = TrackFlatter.flatten changes
        end
      end
    end

    def union(deltas)
      deltas.each_with_object({}) do |delta, hash|
        delta.each do |collection, elements|
          hash[collection] ||= {}
          elements.each do |id, change|
            hash[collection][id] ||= []
            hash[collection][id] << change
          end
        end
      end
    end

    def has_current_changes_for?(collection, id)
      current_delta.key?(collection) && current_delta[collection].key?(id)
    end

    def current_action_for(collection, id)
      current_delta[collection][id]['action'] if has_current_changes_for? collection, id
    end

    def calculate_index_delta
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
    
  end
end