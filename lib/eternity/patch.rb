module Eternity
  class Patch

    attr_reader :current_commit, :target_commit
    
    def initialize(current_commit, target_commit)
      @current_commit = current_commit
      @target_commit = target_commit
    end

    def commits
      [current_commit, target_commit]
    end

    def commit_ids
      commits.map(&:id)
    end

    def base
      @base ||= Commit.find_base current_commit, target_commit
    end

    def current_delta
      @current_delta ||= current_commit.delta_base_from base
    end

    def target_delta
      @target_delta ||= target_commit.delta_base_from base
    end

    def base_delta
      @base_delta ||= Delta.merge current_delta, target_delta
    end

    def apply_to(index)
      target_commit.with_index do |tmp_index|
        target_delta.each do |collection, changes|
          if changes.key? ADDED
            changes[ADDED].each do |id|
              index[collection].add id, tmp_index[collection].get_data(id)
            end
          end

          if changes.key? UPDATED
            changes[UPDATED].each do |id|
              index[collection].update id, tmp_index[collection].get_data(id)
            end
          end

          if changes.key? REMOVED
            changes[REMOVED].each do |id|
              index[collection].remove id
            end
          end
        end
      end
    end

  end
end