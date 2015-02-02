require 'minitest_helper'

describe Repository, 'Branch' do

  describe 'Global' do

    let(:commit_id) { SecureRandom.uuid }

    it 'Get/Set' do
      Branch[:test].id.must_be_nil
      Branch[:test] = commit_id
      Branch[:test].id.must_equal commit_id
    end

    it 'Exists' do
      refute Branch.exists?(:test)
      Branch[:test] = commit_id
      assert Branch.exists?(:test)
    end

    it 'Delete' do
      Branch[:test] = commit_id
      assert Branch.exists?(:test)
      Branch.delete :test
      refute Branch.exists?(:test)
    end

  end

  describe 'Local' do

    let(:repository) { Repository.new :test }

    it 'New' do
      repository[:countries].insert 'AR', name: 'Argentina'
      commit = repository.commit author: 'User', message: 'Commit message'

      repository.current_commit.id.must_equal commit.id
      repository.current_branch.must_equal 'master'
      repository.branches.to_h.must_equal 'master' => commit.id

      repository.branch :test_branch

      repository.current_branch.must_equal 'master'
      repository.branches.to_h.must_equal 'master' => commit.id, 
                                          'test_branch' => commit.id
    end

    it 'Without commit' do
      error = proc { repository.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal "Can't branch without commit"
    end
    
    it 'With uncommitted changes' do
      repository[:countries].insert 'AR', name: 'Argentina'
      commit_id = repository.commit author: 'User', message: 'Commit message'
      repository[:countries].delete 'AR'

      error = proc { repository.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal "Can't branch with uncommitted changes"
    end

  end

end