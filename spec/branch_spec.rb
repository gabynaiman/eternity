require 'minitest_helper'

describe Session, 'Branch' do

  let(:session) { Session.new :test }

  it 'New' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit = session.commit author: 'User', message: 'Commit message'

    session.current_commit.id.must_equal commit.id
    session.current_branch.must_equal 'master'
    session.branches.to_h.must_equal 'master' => commit.id

    session.branch :test_branch

    session.current_branch.must_equal 'master'
    session.branches.to_h.must_equal 'master' => commit.id, 
                                     'test_branch' => commit.id
  end

  it 'Without commit' do
    error = proc { session.branch :test_branch }.must_raise RuntimeError
    error.message.must_equal "Can't branch without commit"
  end
  
  it 'With uncommitted changes' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_id = session.commit author: 'User', message: 'Commit message'
    session[:countries].delete 'AR'

    error = proc { session.branch :test_branch }.must_raise RuntimeError
    error.message.must_equal "Can't branch with uncommitted changes"
  end

end