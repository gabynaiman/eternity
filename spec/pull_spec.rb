require 'minitest_helper'

describe Repository, 'Pull' do

  let(:repository) { Repository.new :test }

  it 'With uncommitted changes' do
    repository[:countries].insert 'AR', name: 'Argentina'

    error = proc { repository.pull }.must_raise RuntimeError
    error.message.must_equal "Can't pull with uncommitted changes"
  end

  it 'Invalid remote branch' do
    error = proc { repository.pull }.must_raise RuntimeError
    error.message.must_equal 'Branch not found: master'
  end

  it 'Without previous commit' do
    other_repository = Repository.new :other
    other_repository[:countries].insert 'AR', name: 'Argentina'
    commit = other_repository.commit author: 'User', message: 'Commit 1'
    other_repository.push

    repository.pull

    repository.current_commit.id.must_equal commit.id
    repository.branches[repository.current_branch].must_equal commit.id
  end

  it 'Up to date' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push
    
    repository.pull

    repository.current_commit.id.must_equal commit_1.id
  end

  it 'Ahead of branch' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'

    repository.push

    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'

    repository.pull

    repository.current_commit.id.must_equal commit_2.id
  end

  it 'Fast-forward' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push
    
    other_repository = Repository.new :other
    other_repository.pull

    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'
    repository.push

    other_repository.wont_be :changes?
    other_repository.current_commit.id.must_equal commit_1.id
    other_repository.branches[other_repository.current_branch].must_equal commit_1.id

    other_repository.pull

    other_repository.wont_be :changes?
    other_repository.current_commit.id.must_equal commit_2.id
    other_repository.branches[other_repository.current_branch].must_equal commit_2.id
  end

  it 'Merge' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push
    
    other_repository = Repository.new :other
    other_repository.pull
    
    other_repository[:countries].insert 'UY', name: '...'
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'

    other_repository[:countries].update 'UY', name: 'Uruguay'
    commit_3 = other_repository.commit author: 'User', message: 'Commit 3'

    other_repository.push

    repository[:countries].insert 'BR', name: 'Brasil'
    commit_4 = repository.commit author: 'User', message: 'Commit 4'

    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id

    repository.current_commit.tap do |commit|
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
    repository[:countries].insert 'AR', name: 'Argentina 1'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push
    
    other_repository = Repository.new :other
    other_repository.pull

    other_repository[:countries].update 'AR', name: 'Argentina 2'
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'
    other_repository.push

    repository[:countries].update 'AR', name: 'Argentina 3'
    commit_3 = repository.commit author: 'User', message: 'Commit 3'
    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id

    repository.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina 2'}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina 2')}
    end
  end

  it 'Merge different changes for same object' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push

    other_repository = Repository.new :other
    other_repository.pull

    other_repository[:countries].update 'AR', name: 'Argentina', number: 54
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'
    other_repository.push

    repository[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    commit_3 = repository.commit author: 'User', message: 'Commit 3'
    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id

    repository.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG', 'number' => 54}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG', number: 54)}
    end
  end

  it 'Merge added same object in differents repositorys' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push

    other_repository = Repository.new :other
    other_repository.pull

    other_repository[:countries].insert 'X', name: 'X1', code: 1
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'
    other_repository.push

    repository[:countries].insert 'X', name: 'X2', number: 2
    commit_3 = repository.commit author: 'User', message: 'Commit 3'
    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id
    
    repository.current_commit.tap do |commit|
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

  it 'Merge removed same object in differents repositorys' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push

    other_repository = Repository.new :other
    other_repository.pull

    other_repository[:countries].delete 'AR'
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'
    other_repository.push

    repository[:countries].delete 'AR'
    commit_3 = repository.commit author: 'User', message: 'Commit 3'
    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id
    
    repository.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'delete'}}
      commit.delta.must_be_empty
      commit.must_have_empty_index
    end
  end

  it 'Merge updated object previously removed' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    repository.push

    other_repository = Repository.new :other
    other_repository.pull

    other_repository[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    commit_2 = other_repository.commit author: 'User', message: 'Commit 2'
    other_repository.push

    repository[:countries].delete 'AR'
    commit_3 = repository.commit author: 'User', message: 'Commit 3'
    repository.pull

    repository.branches[repository.current_branch].must_equal repository.current_commit.id

    repository.current_commit.tap do |commit|
      commit.parent_ids.must_equal [commit_3.id, commit_2.id]
      commit.base.id.must_equal commit_1.id
      commit.base_delta.must_equal 'countries' => {'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG'}}}
      commit.delta.must_be_empty
      commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG')}
    end
  end

end