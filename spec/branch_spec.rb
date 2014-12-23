require 'minitest_helper'

describe 'Branch' do
  
  let(:session) { Session.new :test }

  it 'Initial status' do
    session.current_commit?.must_equal false
    session.current_commit.must_be_nil
    session.current_branch.must_equal 'master'
    session.branches.must_be_empty
  end

  it 'Create' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_id = session.commit author: 'User', message: 'Commit message'

    session.current_commit?.must_equal true
    session.current_commit.id.must_equal commit_id
    session.current_branch.must_equal 'master'
    session.branches.to_h.must_equal 'master' => commit_id

    session.branch :test_branch

    session.current_branch.must_equal 'master'
    session.branches.to_h.must_equal 'master' => commit_id, 
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