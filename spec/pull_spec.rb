require 'minitest_helper'

describe Session, 'Pull' do

  let(:session) { Session.new :test }

  it 'With uncommitted changes' do
    session[:countries].insert 'AR', name: 'Argentina'

    error = proc { session.pull }.must_raise RuntimeError
    error.message.must_equal "Can't pull with uncommitted changes"
  end

  it 'Invalid remote branch' do
    error = proc { session.pull }.must_raise RuntimeError
    error.message.must_equal 'Branch not found: master'
  end

  it 'Without previous commit' do
    commit_id = '123456789'
    Branch[:master] = commit_id

    session.pull

    session.current_commit.id.must_equal commit_id
    session.branches[session.current_branch].must_equal commit_id
  end

  it 'Up to date' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    session.pull

    session.current_commit.id.must_equal commit_1.id
  end

  it 'Ahead of branch' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'

    session.push

    session[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'

    session.pull

    session.current_commit.id.must_equal commit_2.id
  end

  it 'Fast-forward' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    other_session = Session.new :other
    other_session.pull

    session[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = session.commit author: 'User', message: 'Commit 2'
    session.push

    other_session.wont_be :changes?
    other_session.current_commit.id.must_equal commit_1.id
    other_session.branches[other_session.current_branch].must_equal commit_1.id

    other_session.pull

    other_session.wont_be :changes?
    other_session.current_commit.id.must_equal commit_2.id
    other_session.branches[other_session.current_branch].must_equal commit_2.id
  end

  it 'Merge' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push
    
    other_session = Session.new :other
    other_session.pull
    
    other_session[:countries].insert 'UY', name: '...'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'

    other_session[:countries].update 'UY', name: 'Uruguay'
    commit_3 = other_session.commit author: 'User', message: 'Commit 3'

    other_session.push

    session[:countries].insert 'BR', name: 'Brasil'
    commit_4 = session.commit author: 'User', message: 'Commit 4'

    session.pull

    session.branches[session.current_branch].must_equal session.current_commit.id

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_4.id, commit_3.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {
        'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}}, 
        'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}
      }
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay'),
        'BR' => digest(name: 'Brasil')
      }
    end
  end

  it 'Merge with conflicts' do
    session[:countries].insert 'AR', name: 'Argentina 1'
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

    session.branches[session.current_branch].must_equal session.current_commit.id

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina 2'}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina 2')}
    end
  end

  it 'Merge different changes for same object' do
    session[:countries].insert 'AR', name: 'Argentina'
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

    session.branches[session.current_branch].must_equal session.current_commit.id

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG', 'number' => 54}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG', number: 54)}
    end
  end

  it 'Merge added same object in differents sessions' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].insert 'X', name: 'X1', code: 1
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].insert 'X', name: 'X2', number: 2
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.branches[session.current_branch].must_equal session.current_commit.id
    
    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'X' => {'action' => 'insert', 'data' => {'name' => 'X1', 'number' => 2, 'code' => 1}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina'),
        'X'  => digest(name: 'X1', 'number' => 2, 'code' => 1)
      }
    end
  end

  it 'Merge removed same object in differents sessions' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].delete 'AR'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].delete 'AR'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.branches[session.current_branch].must_equal session.current_commit.id
    
    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'delete'}}
      commit.delta.must_be_empty
      commit.must_have_empty_index
    end
  end

  it 'Merge updated object previously removed' do
    session[:countries].insert 'AR', name: 'Argentina'
    commit_1 = session.commit author: 'User', message: 'Commit 1'
    session.push

    other_session = Session.new :other
    other_session.pull

    other_session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    commit_2 = other_session.commit author: 'User', message: 'Commit 2'
    other_session.push

    session[:countries].delete 'AR'
    commit_3 = session.commit author: 'User', message: 'Commit 3'
    session.pull

    session.branches[session.current_branch].must_equal session.current_commit.id

    session.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG'}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG')}
    end
  end

end