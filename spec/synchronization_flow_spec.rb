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

    it 'Valid' do
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

    it 'Without commit' do
      error = proc { session.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant branch without commit'
    end
    
    it 'With uncommitted changes' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_id = session.commit author: 'User', message: 'Commit message'
      session[:countries].remove 'AR'

      error = proc { session.branch :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant branch with uncommitted changes'
    end

  end

  describe 'Checkout' do

    it 'Local branch' do
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

    it 'With uncommitted changes' do
      session[:countries].add 'AR', name: 'Argentina'

      error = proc { session.checkout :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Cant checkout with uncommitted changes'
    end

    it 'Remote branch' do
      other_session = Session.new :other
      other_session[:countries].add 'AR', name: 'Argentina'
      commit_id = other_session.commit author: 'User', message: 'Commit message'

      Branch.new(:test_branch).commit_id = commit_id

      session.checkout :test_branch

      session.current_commit?.must_equal true
      session.current_commit.id.must_equal commit_id
      session.current_branch.must_equal 'test_branch'
      session.branches.must_equal 'test_branch' => commit_id

      session.delta.must_be_empty
      session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    end

    it 'Invalid branch' do
      error = proc { session.checkout :test_branch }.must_raise RuntimeError
      error.message.must_equal 'Invalid branch test_branch'
    end

  end

  describe 'Push' do

    it 'New branch' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_id = session.commit author: 'User', message: 'Commit message'

      Branch.exists?(:master).must_equal false

      session.push

      Branch.new(:master).commit_id.must_equal commit_id
    end

    it 'Without commit' do
      error = proc { session.push }.must_raise RuntimeError
      error.message.must_equal 'Cant push without commit'
    end

    it 'Fast-forward' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_1 = session.commit author: 'User', message: 'Commit 1'

      session[:countries].add 'UY', name: 'Uruguay'
      commit_2 = session.commit author: 'User', message: 'Commit 2'

      branch = Branch.new :master
      branch.commit_id = commit_1

      session.push

      branch.commit_id.must_equal commit_2
    end

    it 'Rejected' do
      session[:countries].add 'AR', name: 'Argentina'
      session.commit author: 'User', message: 'Commit message'

      Branch.new(:master).commit_id = '123456789'

      error = proc { session.push }.must_raise RuntimeError
      error.message.must_equal 'Push rejected. Non fast forward'
    end

    it 'Forced' do
      session[:countries].add 'AR', name: 'Argentina'
      commit_id = session.commit author: 'User', message: 'Commit message'

      branch = Branch.new :master
      branch.commit_id = '123456789'

      session.push!

      branch.commit_id.must_equal commit_id
    end

  end

  describe 'Pull' do

    # it 'With uncommitted changes'

    # it 'Fast-forward'

    # it 'Merge'

  end

end