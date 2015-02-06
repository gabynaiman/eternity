require 'minitest_helper'

describe 'Locking' do

  let(:repository) { Repository.new :test }
  
  def lock(repo)
    Eternity.locker_adapter[repo.name] = :test_process
  end

  def assert_locked
    error = proc { yield }.must_raise Locky::Error
    error.message.must_equal 'test already locked by test_process'
  end

  it 'Commit' do
    repository[:countries].insert 'AR', name: 'Argentina'
    lock repository
    
    assert_locked { repository.commit author: 'User', message: 'Commit Message' }

    repository.current_commit.must_be_nil
    repository.changes_count.must_equal 1
  end

  it 'Checkout' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    
    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'

    lock repository

    assert_locked { repository.checkout commit: commit_1.id }

    repository.current_commit.must_equal commit_2
  end

  it 'Merge' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'
    
    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'

    repository.checkout commit: commit_1.id

    lock repository

    assert_locked { repository.merge commit: commit_2.id }

    repository.current_commit.must_equal commit_1
  end

  it 'Revert all' do
    repository[:countries].insert 'AR', name: 'Argentina'
    repository[:countries].insert 'UY', name: 'Uruguay'
    repository[:cities].insert 'CABA', name: 'Ciudad Autonoma de Buenos Aires'

    lock repository

    assert_locked { repository.revert }

    repository.changes_count.must_equal 3
    repository[:countries].count.must_equal 2
    repository[:cities].count.must_equal 1
  end

  it 'Revert collection' do
    repository[:countries].insert 'AR', name: 'Argentina'
    repository[:countries].insert 'UY', name: 'Uruguay'
    repository[:cities].insert 'CABA', name: 'Ciudad Autonoma de Buenos Aires'

    lock repository

    assert_locked { repository[:countries].revert_all }

    repository.changes_count.must_equal 3
    repository[:countries].count.must_equal 2
    repository[:cities].count.must_equal 1
  end

  it 'Insert' do
    lock repository

    assert_locked { repository[:countries].insert 'AR', name: 'Argentina' }

    repository.changes_count.must_equal 0
  end

  it 'Update' do
    repository[:countries].insert 'AR', name: 'Argentina'

    lock repository

    assert_locked { repository[:countries].update 'AR', name: 'Republica Argentina' }

    repository.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}
  end

  it 'Delete' do
    repository[:countries].insert 'AR', name: 'Argentina'

    lock repository

    assert_locked { repository[:countries].delete 'AR' }

    repository.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}
  end

  it 'Revert' do
    repository[:countries].insert 'AR', name: 'Argentina'

    lock repository

    assert_locked { repository[:countries].revert 'AR' }

    repository.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}
  end

end