require 'minitest_helper'

describe Session, 'Checkout' do

  let(:session) { Session.new :test }

  it 'Local branch' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'

    session.branch :test_branch

    session[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'

    session.current_branch.must_equal 'master'
    session.current_commit.id.must_equal commit_2.id

    session.checkout :test_branch

    session.current_branch.must_equal 'test_branch'
    session.current_commit.id.must_equal commit_1.id

    session.branches.to_h.must_equal 'master' => commit_2.id, 
                                     'test_branch' => commit_1.id
  end

  it 'Remote branch' do
    other_session = Session.new :other
    other_session[:countries].insert 'AR', name: 'Argentina'
    commit = other_session.commit author: 'User', message: 'Commit message'
    
    Branch[:test_branch] = commit.id

    session.checkout :test_branch

    session.current_branch.must_equal 'test_branch'
    session.current_commit.id.must_equal commit.id
    session.branches.to_h.must_equal 'test_branch' => commit.id
  end

  it 'With uncommitted changes' do
    session[:countries].insert 'AR', name: 'Argentina'

    error = proc { session.checkout :test_branch }.must_raise RuntimeError
    error.message.must_equal "Can't checkout with uncommitted changes"
  end

  it 'Invalid branch' do
    error = proc { session.checkout :test_branch }.must_raise RuntimeError
    error.message.must_equal 'Invalid branch test_branch'
  end

end