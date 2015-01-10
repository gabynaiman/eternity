require 'minitest_helper'

describe Session, 'Push' do

  let(:session) { Session.new :test }

  it 'New branch' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit = session.commit author: 'User', message: 'Commit message'

    Branch.wont_be :exists?, :master

    session.push

    Branch[:master].id.must_equal commit.id
  end

  it 'Without commit' do
    error = proc { session.push }.must_raise RuntimeError
    error.message.must_equal "Can't push without commit"
  end

  it 'Fast-forward' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    session[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'
    session.push

    Branch[:master].id.must_equal commit_2.id
  end

  it 'Rejected' do
    session[:countries].insert 'AR', name: 'Argentina'
    session.commit author: 'User', message: 'Commit message'

    Branch[:master] = '123456789'

    error = proc { session.push }.must_raise RuntimeError
    error.message.must_equal 'Push rejected (non fast forward)'
  end

  it 'Forced' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit = session.commit author: 'User', message: 'Commit message'

    Branch[:master] = '123456789'

    session.push!

    Branch[:master].id.must_equal commit.id
  end

end