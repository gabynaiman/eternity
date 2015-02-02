require 'minitest_helper'

describe Repository do

  let(:repository) { Repository.new :test }

  it 'Initial status' do
    repository.wont_be :changes?
    repository.changes_count.must_equal 0
    repository.wont_be :current_commit?
    repository.current_branch.must_equal 'master'
    repository.branches.must_be_empty
  end

  it 'Empty' do
    repository.must_be_empty

    repository[:countries].insert 'AR', name: 'Argentina'
    commit = repository.commit author: 'User', message: 'Commit message'

    repository.wont_be_empty
  end

  it 'Destroy' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit = repository.commit author: 'User', message: 'Commit message'

    repository.destroy

    repository.must_be_empty
  end

  it 'Replace delta' do
    repository[:countries].insert 'AR', name: 'Argentina'

    repository.delta = {'countries' => {'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}}}

    repository.to_h['tracker'].must_equal 'countries' => {'UY' => [{'action' => 'insert', 'blob' => digest(name: 'Uruguay')}]}
  end

  it 'To hash' do
    repository[:countries].insert 'AR', name: 'Argentina'
    commit = repository.commit author: 'User', message: 'Commit message'
    repository[:countries].insert 'UY', name: 'Uruguay'

    repository.to_h.must_equal 'current'  => {'commit' => repository.current_commit.id}, 
                               'branches' => {'master' => repository.current_commit.id}, 
                               'tracker'  => {'countries' => {'UY' => [{'action' => 'insert', 'blob' => digest(name: 'Uruguay')}]}}
  end

end