require 'minitest_helper'

describe Commit do

  let(:session) { Session.new :test }

  it 'First commit' do
    session[:countries].add 'AR', name: 'Argentina'

    commit_id = session.commit author: 'User', message: 'Commit message'

    session.delta.must_be_empty
    session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    
    session.head_id.must_equal commit_id
    session.head.time.must_be_instance_of Time
    session.head.author.must_equal 'User'
    session.head.message.must_equal 'Commit message'
    session.head.parents.must_equal []
    session.head.delta.must_equal 'countries' => {'added' => ['AR']}
    session.head.index_dump.must_equal_index 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
  end

  it 'Chained commits' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'

    session[:countries].add 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'

    session.head_id.must_equal commit_2
    session.head.time.must_be_instance_of Time
    session.head.author.must_equal 'User'
    session.head.message.must_equal 'Commit 2'
    session.head.parent_ids.must_equal [commit_1]
    session.head.delta.must_equal 'countries' => {'added' => ['UY']}
    session.head.index_dump.must_equal_index 'countries' => {
      'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8', 
      'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
    }
  end

  it 'Nothing to commit' do
    error = proc { session.commit author: 'User', message: 'Commit message' }.must_raise RuntimeError
    error.message.must_equal 'Nothing to commit'
  end

end