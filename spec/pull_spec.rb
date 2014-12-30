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
    other_session.entries.must_equal 'countries' => {'AR' => digest(name: 'Argentina')}

    other_session.pull

    other_session.current_commit_id.must_equal commit_2
    other_session.branches[other_session.current_branch].must_equal commit_2
    other_session.changes.must_be_empty
    other_session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'UY' => digest(name: 'Uruguay')
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
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay'),
        'BR' => digest(name: 'Brasil')
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina'), 
      'UY' => digest(name: 'Uruguay'),
      'BR' => digest(name: 'Brasil')
    }
  end

  it 'Merge with conflicts' do
    session[:countries].add 'AR', name: 'Argentina 1'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    other_session = Session.new :other
    other_session.pull

    other_session[:countries].update 'AR', name: 'Argentina 2'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].update 'AR', name: 'Argentina 3'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3, commit_2]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'updated' => ['AR']}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina 2')
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina 2')
    }
  end

  it 'Merge different changes for same object' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].update 'AR', name: 'Argentina', number: 54
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3, commit_2]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'updated' => ['AR']}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina', code: 'ARG', number: 54)
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina', code: 'ARG', number: 54)
    }
  end

  it 'Merge added same object in differents sessions' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].add 'X', name: 'X1', code: 1
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].add 'X', name: 'X2', number: 2
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3, commit_2]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'added' => ['X']}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina'),
        'X'  => digest(name: 'X1', number: 2, code: 1)
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'X'  => digest(name: 'X1', number: 2, code: 1)
    }
  end

  it 'Merge removed same object in differents sessions' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].remove 'AR'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].remove 'AR'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3, commit_2]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'removed' => ['AR']}
      commit.delta.must_be_empty
      commit.must_have_empty_index 
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_be_empty
  end

  it 'Merge updated object previously removed' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].remove 'AR'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3, commit_2]
      commit.base_id.must_equal commit_1
      commit.base_delta.must_equal 'countries' => {'updated' => ['AR']}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina', code: 'ARG')
      }
    end

    session.branches[session.current_branch].must_equal session.current_commit_id
    
    session.changes.must_be_empty
    session.entries.must_equal 'countries' => {
      'AR' => digest(name: 'Argentina', code: 'ARG')
    }
  end

end