require 'minitest_helper'

describe 'Pull' do
  
  let(:session) { Session.new :test }

  it 'With uncommitted changes' do
    session[:countries].add 'AR', name: 'Argentina'

    error = proc { session.pull }.must_raise RuntimeError
    error.message.must_equal 'Cant pull with uncommitted changes'
  end

  it 'Invalid remote branch' do
    error = proc { session.pull }.must_raise RuntimeError
    error.message.must_equal 'Branch not found: master'
  end

  it 'Fast-forward' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    other_session = Session.new :other
    other_session.pull

    session[:countries].add 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'
    session.push

    other_session.current_commit_id.must_equal commit_1
    other_session.branches[other_session.current_branch].must_equal commit_1
    other_session.changes.must_be_empty
    other_session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}

    other_session.pull

    other_session.current_commit_id.must_equal commit_2
    other_session.branches[other_session.current_branch].must_equal commit_2
    other_session.changes.must_be_empty
    other_session.entries.must_equal 'countries' => {
      'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8',
      'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
    }
  end

  it 'Merge' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    other_session = Session.new :other
    other_session.pull
    
    other_session[:countries].add 'UY', name: '...'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    
    other_session[:countries].update 'UY', name: 'Uruguay'
    commit_3 = other_session.commit author: 'User', message: 'Commit 3'
    
    other_session.push

    session[:countries].add 'BR', name: 'Brasil'
    commit_4 = session.commit author: 'User', message: 'Commit 4'

    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_4, commit_3]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'added' => ['BR', 'UY']}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8', 
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f',
        'BR' => 'd9623f086a613d36cf0cc5692c2542750e099ba9'
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8',
      'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f',
      'BR' => 'd9623f086a613d36cf0cc5692c2542750e099ba9'
    }
  end

  # it 'Merge with conflicts'

end