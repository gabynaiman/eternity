require 'minitest_helper'

describe Repository, 'Checkout' do

  let(:repository) { Repository.new :test }

  it 'Local branch' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'

    repository.branch :test_branch

    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'

    repository.current_branch.must_equal 'master'
    repository.current_commit.id.must_equal commit_2.id

    repository.checkout :test_branch

    repository.current_branch.must_equal 'test_branch'
    repository.current_commit.id.must_equal commit_1.id

    repository.branches.to_h.must_equal 'master' => commit_2.id, 
                                     'test_branch' => commit_1.id
  end

  it 'Remote branch' do
    other_repository = Repository.new :other
    other_repository[:countries].insert 'AR', name: 'Argentina'
    commit = other_repository.commit author: 'User', message: 'Commit message'
    
    Branch[:test_branch] = commit.id

    repository.checkout :test_branch

    repository.current_branch.must_equal 'test_branch'
    repository.current_commit.id.must_equal commit.id
    repository.branches.to_h.must_equal 'test_branch' => commit.id
  end

  it 'With uncommitted changes' do
    repository[:countries].insert 'AR', name: 'Argentina'

    error = proc { repository.checkout :test_branch }.must_raise RuntimeError
    error.message.must_equal "Can't checkout with uncommitted changes"
  end

  it 'Invalid branch' do
    error = proc { repository.checkout :test_branch }.must_raise RuntimeError
    error.message.must_equal 'Invalid branch test_branch'
  end

end