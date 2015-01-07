require 'minitest_helper'

describe 'Commit' do

  let(:session) { Session.new :test }

  it 'First commit' do
    session[:countries].add 'AR', name: 'Argentina'

    commit_id = session.commit author: 'User', message: 'Commit message'

    session.changes.must_be_empty
    session.must_equal_index 'countries' => {'AR' => {'name' => 'Argentina'}}
    
    session.current_commit_id.must_equal commit_id
    session.current_commit.time.must_be_instance_of Time
    session.current_commit.author.must_equal 'User'
    session.current_commit.message.must_equal 'Commit message'
    session.current_commit.parents.must_equal []
    session.current_commit.delta.must_equal 'countries' => {'added' => ['AR']}
    session.current_commit.must_equal_index 'countries' => {'AR' => {'name' => 'Argentina'}}
  end

  it 'Chained commits' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'

    session[:countries].add 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'

    session.current_commit_id.must_equal commit_2
    session.current_commit.time.must_be_instance_of Time
    session.current_commit.author.must_equal 'User'
    session.current_commit.message.must_equal 'Commit 2'
    session.current_commit.parent_ids.must_equal [commit_1]
    session.current_commit.delta.must_equal 'countries' => {'added' => ['UY']}
    session.current_commit.must_equal_index 'countries' => {
      'AR' => {'name' => 'Argentina'}, 
      'UY' => {'name' => 'Uruguay'}
    }
  end

  it 'Nothing to commit' do
    error = proc { session.commit author: 'User', message: 'Commit message' }.must_raise RuntimeError
    error.message.must_equal 'Nothing to commit'
  end

end