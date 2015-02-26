require 'minitest_helper'

describe Repository, 'Pull' do

  let(:repo_1) { Repository.new :test_1 }
  let(:repo_2) { Repository.new :test_2 }
  let(:repo_3) { Repository.new :test_3 }

  it 'test' do
    repo_1[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repo_1.commit author: 'User 1', message: 'Commit 1'
    repo_1.push

    repo_2.pull
    repo_3.pull

    repo_2[:countries].insert 'BR', name: 'Brasil'
    commit_2 = repo_2.commit author: 'User 2', message: 'Commit 2'

    repo_2[:countries].update 'AR', name: 'Argentina', code: 54, capital: '...'
    commit_3 = repo_2.commit author: 'User 2', message: 'Commit 3'

    repo_1[:countries].update 'AR', name: 'Argentina', capital: 'CABA'
    commit_4 = repo_1.commit author: 'User 1', message: 'Commit 4'

    repo_1[:countries].insert 'CL', name: 'Chile'
    commit_5 = repo_1.commit author: 'User 1', message: 'Commit 5'

    repo_1.push

    delta = repo_2.pull
    commit_6 = repo_2.current_commit # Merge

    delta.must_equal 'countries' => {
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 54, 'capital' => 'CABA'}},
      'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
    }

    commit_6.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', code: 54, capital: 'CABA'),
      'BR' => digest(name: 'Brasil'),
      'CL' => digest(name: 'Chile')
    }

    repo_2.push

    delta = repo_1.pull

    repo_1.current_commit.must_equal commit_6

    delta.must_equal 'countries' => {
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 54, 'capital' => 'CABA'}},
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}},
      'CL' => {'action' => 'update', 'data' => {'name' => 'Chile'}}
    }

    repo_2[:countries].delete 'CL'
    repo_2[:countries].insert 'PY', name: 'Paraguay'
    commit_7 = repo_2.commit author: 'User 2', message: 'Commit 7'

    repo_1[:countries].insert 'CO', name: 'Colombia'
    commit_8 = repo_1.commit author: 'User 1', message: 'Commit 8'

    repo_1.push

    delta = repo_2.pull
    commit_9 = repo_2.current_commit # Merge

    delta.must_equal 'countries' => {
      'CO' => {'action' => 'insert', 'data' => {'name' => 'Colombia'}}
    }

    commit_9.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', code: 54, capital: 'CABA'),
      'BR' => digest(name: 'Brasil'),
      'PY' => digest(name: 'Paraguay'),
      'CO' => digest(name: 'Colombia')
    }

    repo_2[:countries].delete 'CO'
    commit_10 = repo_2.commit author: 'User 2', message: 'Commit 10'

    repo_2.push

    delta = repo_1.pull

    repo_1.current_commit.must_equal commit_10

    delta.must_equal 'countries' => {
      'CL' => {'action' => 'delete'},
      'PY' => {'action' => 'insert', 'data' => {'name' => 'Paraguay'}},
      'CO' => {'action' => 'delete'}
    }

    repo_3[:countries].insert 'UY', name: 'Uruguay'
    commit_11 = repo_3.commit author: 'User 3', message: 'Commit 11'

    delta = repo_3.checkout commit: commit_10.id

    repo_3.current_commit.must_equal commit_10

    delta.must_equal 'countries' => {
      'UY' => {'action' => 'delete'},
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 54, 'capital' => 'CABA'}},
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}},
      'PY' => {'action' => 'insert', 'data' => {'name' => 'Paraguay'}}
    }
  end

end