require 'minitest_helper'

describe 'Synchronization flow' do
  
  let(:session) { Session.new :test }

  it 'Initial status' do
    session.current_commit?.must_equal false
    session.current_commit.must_be_nil
    session.current_branch.must_equal 'master'
    session.branches.must_be_empty
  end

  describe 'Create branch' do

    it 'Success' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_id = session.commit author: 'User', message: 'Commit message'

      session.current_commit?.must_equal true
      session.current_commit.id.must_equal commit_id
      session.current_branch.must_equal 'master'
      session.branches.must_equal 'master' => commit_id

      session.branch :test_branch

      session.current_branch.must_equal 'master'
      session.branches.must_equal 'master' => commit_id, 
                                  'test_branch' => commit_id
    end

    it 'Fail without commit' do
      error = proc { session.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant branch without commit'
    end
    
    it 'Fail with uncommitted changes' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_id = session.commit author: 'User', message: 'Commit message'
      session[:countries].remove 'AR'

      error = proc { session.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant branch with uncommitted changes'
    end

  end

  describe 'Checkout branch' do

    it 'Checkout local branch' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_1 = session.commit author: 'User', message: 'Commit 1'

      session.branch :test_branch

      session[:countries].add 'UY', name: 'Uruguay'
      commit_2 = session.commit author: 'User', message: 'Commit 2'

      session.checkout :test_branch

      session.current_commit?.must_equal true
      session.current_commit.id.must_equal commit_1
      session.current_branch.must_equal 'test_branch'
      session.branches.must_equal 'master' => commit_2, 
                                  'test_branch' => commit_1

      session.delta.must_be_empty
      session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    end

    it 'Checkout with uncommitted changes' do
      session[:countries].add 'AR', name: 'Argentina'

      error = proc { session.checkout :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant checkout with uncommitted changes'
    end

    it 'Checkout remote branch' do
      other_session = Session.new :other
      other_session[:countries].add 'AR', name: 'Argentina'
      commit_id = other_session.commit author: 'User', message: 'Commit message'

      branch = Branch.new :test_branch
      branch.commit_id = commit_id

      session.checkout :test_branch

      session.current_commit?.must_equal true
      session.current_commit.id.must_equal commit_id
      session.current_branch.must_equal 'test_branch'
      session.branches.must_equal 'test_branch' => commit_id

      session.delta.must_be_empty
      session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    end

    it 'Checkout invalid branch' do
      error = proc { session.checkout :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Invalid branch test_branch'
    end

  end

  # it 'Push'

  # it 'Push rejected'

  # it 'Pull fast-forward'

  # it 'Pull with merge'

end


=begin

session_1 = Session.new :user_1

session_1.head.branch # => master

session_1.index[:countries].add 'AR', name: 'Argentina'
session_1.commit message: 'Commit 1', author: 'user'
session_1.push # master

session_1.branch :spanish
session_1.checkout :spanish

session_1.index[:countries].add 'BR', name: 'Brasil'
session_1.commit message: 'Commit 2', author: 'user'
session_1.push # spanish

# -----------------------------------

session_2 = Session.new :user_2

session_2.head.branch # => master

session_2.checkout :spanish
session_2.pull # spanish
# => session_2.merge 123456798
# => session_2.commit message: 'Merge spanish to spanish', author: 'system'

session_2.checkout :master
session_2.merge_branch :spanish # merge 123456798
# => session_2.commit message: 'Merge spanish to master', author: 'system'
session_2.push # master

=end
