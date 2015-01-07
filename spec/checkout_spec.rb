require 'minitest_helper'

describe 'Checkout' do
  
  let(:session) { Session.new :test }

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
    session.branches.to_h.must_equal 'master' => commit_2, 
                                     'test_branch' => commit_1

    session.changes.must_be_empty
    session.must_equal_index 'countries' => {'AR' => {'name' => 'Argentina'}}
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
    session.branches.to_h.must_equal 'test_branch' => commit_id

    session.changes.must_be_empty
    session.must_equal_index 'countries' => {'AR' => {'name' => 'Argentina'}}
  end

  it 'Invalid branch' do
    error = proc { session.checkout :test_branch }.must_raise RuntimeError
    error.message.must_equal 'Invalid branch test_branch'
  end

end