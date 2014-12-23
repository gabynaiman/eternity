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
      @current_delta ||= delta_from current_commit, base
    end

    def target_delta
      @target_delta ||= delta_from target_commit, base
    end

    def base_delta
      @base_delta ||= Delta.merge current_delta, target_delta
    end

    def apply_to(index)
      target_commit.with_index do |tmp_index|
        target_delta.each do |section, changes|
          if changes.key? ADDED
            changes[ADDED].each do |id|
              index[section].add id, tmp_index[section].get_data(id)
            end
          end

          if changes.key? UPDATED
            changes[UPDATED].each do |id|
              index[section].update id, tmp_index[section].get_data(id)
            end
          end

          if changes.key? REMOVED
            changes[REMOVED].each do |id|
              index[section].remove id
            end
          end
        end
      end
    end

    private

    def delta_from(commit, base)
      history = [commit] + commit.base_history_at(base.id)[0..-2]
      Delta.merge history.reverse.map(&:base_delta)
    end

  end
end