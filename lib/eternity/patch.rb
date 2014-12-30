module Eternity
  class Patch

    attr_reader :current_commit, :target_commit, :base_commit, 
                :current_delta, :target_delta, :base_delta
    
    def initialize(current_commit, target_commit)
      @current_commit = current_commit
      @target_commit = target_commit
      @base_commit = Commit.find_base current_commit, target_commit
      @current_delta = current_commit.delta_base_from base_commit
      @target_delta = target_commit.delta_base_from base_commit
      @base_delta = Delta.merge current_delta, target_delta
    end

    def commits
      [current_commit, target_commit]
    end

    def commit_ids
      commits.map(&:id)
    end

    def apply_to(index)
      base_commit.with_index do |base_index|
        target_commit.with_index do |target_index|
          target_delta.each do |collection, changes|
            EVENTS.each { |e| changes[e] ||= [] }

            changes[ADDED].each do |id|
              if index[collection].key? id
                data = ConflictResolver.resolve index[collection].value_of(id), 
                                                target_index[collection].value_of(id), 
                                                base_index[collection].value_of(id)
                index[collection].update id, data
              else
                index[collection].add id, target_index[collection].value_of(id)
              end
            end

            changes[UPDATED].each do |id|
              if index[collection].key? id
                if current_delta[collection].key?(UPDATED) && current_delta[collection][UPDATED].include?(id)
                  data = ConflictResolver.resolve index[collection].value_of(id), 
                                                  target_index[collection].value_of(id), 
                                                  base_index[collection].value_of(id)
                  index[collection].update id, data
                else
                  index[collection].update id, target_index[collection].value_of(id)
                end
              else
                index[collection].add id, target_index[collection].value_of(id)
              end
            end

            changes[REMOVED].each do |id|
              index[collection].remove id if index[collection].key? id
            end
          end
        end
      end
    end

  end
end