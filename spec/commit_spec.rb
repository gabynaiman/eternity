require 'minitest_helper'

describe Session, 'Commit' do
  
  let(:session) { Session.new :test }

  it 'Initial status' do
    session.wont_be :changes?
    session.wont_be :current_commit?
    session.current_branch.must_equal 'master'
    session.branches.must_be_empty
  end

  it 'First' do
    session[:countries].insert 'AR', name: 'Argentina'

    session.must_be :changes?
    session.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}

    commit = session.commit author: 'User', message: 'Commit message'

    session.wont_be :changes?
    session.delta.must_be_empty

    session.current_commit.tap do |current_commit|
      current_commit.id.must_equal commit.id
      current_commit.time.must_be_instance_of Time
      current_commit.author.must_equal 'User'
      current_commit.message.must_equal 'Commit message'
      current_commit.parent_ids.must_equal [nil]
      current_commit.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}
      current_commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina')}
    end
  end

  it 'Sequence' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'

    session[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'

    session.current_commit.tap do |current_commit|
      current_commit.id.must_equal commit_2.id
      current_commit.time.must_be_instance_of Time
      current_commit.author.must_equal 'User'
      current_commit.message.must_equal 'Commit 2'
      current_commit.parent_ids.must_equal [commit_1.id]
      current_commit.delta.must_equal 'countries' => {'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}}
      current_commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay')
      }
    end
  end

  it 'No changes' do
    error = proc { session.commit author: 'User', message: 'Commit message' }.must_raise RuntimeError
    error.message.must_equal 'Nothing to commit'
  end
  
end