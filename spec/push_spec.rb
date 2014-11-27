require 'minitest_helper'

describe 'Push' do
  
  let(:session) { Session.new :test }

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