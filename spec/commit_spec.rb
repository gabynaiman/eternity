require 'minitest_helper'

describe Repository, 'Commit' do
  
  let(:repository) { Repository.new :test }

  it 'First' do
    repository[:countries].insert 'AR', name: 'Argentina'

    repository.must_be :changes?
    repository.changes_count.must_equal 1
    repository.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}

    commit = repository.commit author: 'User', message: 'Commit message'

    repository.wont_be :changes?
    repository.changes_count.must_equal 0
    repository.delta.must_be_empty

    repository.current_commit.tap do |current_commit|
      current_commit.must_equal commit
      current_commit.time.must_be_instance_of Time
      current_commit.author.must_equal 'User'
      current_commit.message.must_equal 'Commit message'
      current_commit.parent_ids.must_equal [nil]
      current_commit.must_be :first?
      current_commit.wont_be :merge?
      current_commit.delta.must_equal 'countries' => {'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}}
      current_commit.must_equal_index 'countries' => {'AR' => digest(name: 'Argentina')}
    end
  end

  it 'Sequence' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repository.commit author: 'User', message: 'Commit 1'

    repository[:countries].insert 'UY', name: 'Uruguay'
    commit_2 = repository.commit author: 'User', message: 'Commit 2'

    repository.current_commit.tap do |current_commit|
      current_commit.must_equal commit_2
      current_commit.time.must_be_instance_of Time
      current_commit.author.must_equal 'User'
      current_commit.message.must_equal 'Commit 2'
      current_commit.parent_ids.must_equal [commit_1.id]
      current_commit.wont_be :first?
      current_commit.wont_be :merge?
      current_commit.delta.must_equal 'countries' => {'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}}
      current_commit.must_equal_index 'countries' => {
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay')
      }
    end
  end

  it 'No changes' do
    error = proc { repository.commit author: 'User', message: 'Commit message' }.must_raise RuntimeError
    error.message.must_equal 'Nothing to commit'
  end

  it 'Empty author' do
    repository[:countries].insert 'AR', name: 'Argentina'
    error = proc { repository.commit author: '', message: 'Commit message' }.must_raise RuntimeError
    error.message.must_equal 'Author must be present'
  end

  it 'Empty message' do
    repository[:countries].insert 'AR', name: 'Argentina'
    error = proc { repository.commit author: 'User', message: '' }.must_raise RuntimeError
    error.message.must_equal 'Message must be present'
  end

  describe 'With index' do

    def assert_transeint_index
      redis.call('KEYS', Eternity.keyspace[:index]['*']).must_be_empty
    end

    it 'Transient' do
      repository[:countries].insert 'AR', name: 'Argentina'
      repository[:countries].insert 'UY', name: 'Uruguay'
      commit = repository.commit author: 'User', message: 'Commit 1'

      commit.with_index { |i| i[:countries].ids }.must_equal %w(AR UY)

      assert_transeint_index
    end

    it 'Invalid commit' do
      commit = Commit.new 'invalid'
      proc { commit.with_index { fail 'Invalid commit' } }.must_raise RuntimeError
      assert_transeint_index      
    end

    it 'Invalid block' do
      commit = Commit.new nil
      error = proc { commit.with_index { raise 'Test error' } }.must_raise RuntimeError
      error.message.must_equal 'Test error'
      assert_transeint_index
    end

  end
  
end