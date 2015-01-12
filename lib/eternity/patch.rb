module Eternity
  class Patch

    attr_reader :current_commit, :target_commit, :base_commit, 
                :current_delta,  :target_delta,  :base_delta
    
    def initialize(current_commit, target_commit)
      @current_commit = current_commit
      @target_commit = target_commit
      @base_commit = Commit.find_base current_commit, target_commit
      @current_delta = current_commit.delta_base_from base_commit
      @target_delta = target_commit.delta_base_from base_commit
      @base_delta = {} #Delta.merge current_delta, target_delta
    end

    def commits
      [current_commit, target_commit]
    end

    def commit_ids
      commits.map(&:id)
    end

    def delta
      {}
    end
    
  end
end