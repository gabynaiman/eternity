require 'minitest_helper'

describe 'Delta' do

  let(:repo_1) { Repository.new :test_1 }
  let(:repo_2) { Repository.new :test_2 }
  let(:repo_3) { Repository.new :test_3 }

  it 'Merge -> Checkout (2 times)' do
    #               P           P         P
    # REPO 1: (*)--(1)---(4)---(5)  (6)--(8)       (10)
    #               \           \   /     \        / \
    # REPO 2:        -(2)--(3)---(6)--(7)--(9)--(10) \
    #                \            MP        M    P   \
    # REPO 3:         ------(11)                    (10)  
    #

    repo_1[:countries].insert 'AR', name: 'Argentina'
    commit_1 = repo_1.commit author: 'User 1', message: 'Commit 1'
    repo_1.push

    repo_2.pull
    repo_3.pull

    repo_2[:countries].insert 'BR', name: 'Brasil'
    commit_2 = repo_2.commit author: 'User 2', message: 'Commit 2'

    repo_2[:countries].update 'AR', name: 'Argentina', number: 54, capital: 'CABA'
    commit_3 = repo_2.commit author: 'User 2', message: 'Commit 3'

    repo_1[:countries].update 'AR', name: 'Argentina', capital: '...', code: 'ARG'
    commit_4 = repo_1.commit author: 'User 1', message: 'Commit 4'

    repo_1[:countries].insert 'CL', name: 'Chile'
    commit_5 = repo_1.commit author: 'User 1', message: 'Commit 5'

    repo_1.push

    patch = repo_2.pull
    delta = patch.delta
    commit_6 = repo_2.current_commit # Merge

    delta.must_equal 'countries' => {
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'number' => 54, 'code' => 'ARG', 'capital' => 'CABA'}},
      'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
    }

    commit_6.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54, code: 'ARG', capital: 'CABA'),
      'BR' => digest(name: 'Brasil'),
      'CL' => digest(name: 'Chile')
    }

    repo_2.push

    patch = repo_1.pull
    delta = patch.delta

    repo_1.current_commit.must_equal commit_6

    delta.must_equal 'countries' => {
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'number' => 54, 'code' => 'ARG', 'capital' => 'CABA'}},
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}}
    }

    repo_2[:countries].delete 'CL'
    repo_2[:countries].insert 'PY', name: 'Paraguay'
    commit_7 = repo_2.commit author: 'User 2', message: 'Commit 7'

    repo_1[:countries].insert 'CO', name: 'Colombia'
    commit_8 = repo_1.commit author: 'User 1', message: 'Commit 8'

    repo_1.push

    patch = repo_2.pull
    delta = patch.delta
    commit_9 = repo_2.current_commit # Merge

    delta.must_equal 'countries' => {
      'CO' => {'action' => 'insert', 'data' => {'name' => 'Colombia'}}
    }

    commit_9.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54, code: 'ARG', capital: 'CABA'),
      'BR' => digest(name: 'Brasil'),
      'PY' => digest(name: 'Paraguay'),
      'CO' => digest(name: 'Colombia')
    }

    repo_2[:countries].delete 'CO'
    commit_10 = repo_2.commit author: 'User 2', message: 'Commit 10'

    repo_2.push

    patch = repo_1.pull
    delta = patch.delta

    repo_1.current_commit.must_equal commit_10

    delta.must_equal 'countries' => {
      'CL' => {'action' => 'delete'},
      'PY' => {'action' => 'insert', 'data' => {'name' => 'Paraguay'}},
      'CO' => {'action' => 'delete'}
    }

    repo_3[:countries].insert 'UY', name: 'Uruguay'
    commit_11 = repo_3.commit author: 'User 3', message: 'Commit 11'

    patch = repo_3.checkout commit: commit_10.id
    delta = patch.delta

    repo_3.current_commit.must_equal commit_10

    delta.must_equal 'countries' => {
      'UY' => {'action' => 'delete'},
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'number' => 54, 'code' => 'ARG', 'capital' => 'CABA'}},
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}},
      'PY' => {'action' => 'insert', 'data' => {'name' => 'Paraguay'}}
    }
  end

  it 'Commit -> Pull -> Push (multiple times)' do
    #               P         MP        MP         M
    # REPO 1: (*)--(1)--(3)--(4)--(7)--(8)--(11)--(12)
    #               \      /     \   /     \    /
    # REPO 2:        ---(2)--(5)--(6)--(9)--(10)
    #                    P         MP        MP

    repo_1[:countries].insert 'AR', name: 'Argentina'
    repo_1.commit author: 'User 1', message: 'Added Argentina'
    repo_1.push

    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina')
    }

    repo_2[:countries].insert 'BR', name: 'Brasil'
    repo_2.commit author: 'User 2', message: 'Added Brasil'
    
    patch = repo_2.pull
    delta = patch.delta
    delta.must_be_empty

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil')
    }

    repo_2.push

    repo_1[:countries].insert 'UY', name: 'Uruguay'
    repo_1.commit author: 'User 1', message: 'Added Uruguay'
    
    patch = repo_1.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}}
    }
    
    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Uruguay')
    }

    repo_1.push

    repo_2[:countries].insert 'CL', name: 'Chile'
    repo_2.commit author: 'User 2', message: 'Added Chile'
    
    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Uruguay'),
      'CL' => digest(name: 'Chile')
    }

    repo_2.push

    repo_1[:countries].update 'UY', name: 'Republica Oriental del Uruguay'
    repo_1.commit author: 'User 1', message: 'Updated Uruguay'
    
    patch = repo_1.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
    }

    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Republica Oriental del Uruguay'),
      'CL' => digest(name: 'Chile')
    }

    repo_1.push

    repo_2[:countries].delete 'CL'
    repo_2.commit author: 'User 2', message: 'Deleted Chile'
    
    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'UY' => {'action' => 'update', 'data' => {'name' => 'Republica Oriental del Uruguay'}}
    }
    
    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Republica Oriental del Uruguay')
    }

    repo_2.push

    repo_1[:countries].insert 'CO', name: 'Colombia'
    repo_1.commit author: 'User 1', message: 'Added Colombia'
    
    patch = repo_1.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'CL' => {'action' => 'delete'}
    }

    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Republica Oriental del Uruguay'),
      'CO' => digest(name: 'Colombia')
    }
  end

  it 'Merge -> Merge -> Checkout' do
    #               P             MP   P
    # REPO 1: (*)--(1)--(2)------(6)--(7)
    #                \       MP /       \
    # REPO 2:         --(3)--(5)         (7)
    #                 \     /
    # REPO 3:          -(4)-
    #                    P

    repo_1[:countries].insert 'AR', name: 'Argentina'
    repo_1.commit author: 'User 1', message: 'Commit 1'
    repo_1.push

    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
    }

    patch = repo_3.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}
    }

    repo_3.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
    }

    repo_1[:countries].insert 'BR', name: 'Brasil'
    repo_1.commit author: 'User 1', message: 'Commit 2'

    repo_2[:countries].update 'AR', name: 'Argentina', number: 54
    repo_2.commit author: 'User 2', message: 'Commit 3'

    repo_3[:countries].insert 'UY', name: 'Uruguay'
    repo_3.commit author: 'User 3', message: 'Commit 4'
    repo_3.push

    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'UY' => digest(name: 'Uruguay')
    }

    repo_2.push

    patch = repo_1.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'number' => 54}},
      'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}
    }

    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'BR' => digest(name: 'Brasil'),
      'UY' => digest(name: 'Uruguay')
    }

    repo_1.push

    repo_1[:countries].delete 'UY'
    repo_1.commit author: 'User 1', message: 'Commit 7'
    repo_1.push

    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}},
      'UY' => {'action' => 'delete'}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'BR' => digest(name: 'Brasil')
    }

  end

  it 'Insert -> Delete -> Update' do
    #                 P         P     M
    # REPO 1: (*)----(1)-------(4)---(7)
    #           \       \         \  /
    # REPO 2:    \-(2)--(3)---(5)--(6)
    #                    M          MP

    repo_1[:countries].insert 'AR', name: 'Argentina'
    repo_1.commit author: 'User 1', message: 'Commit 1'
    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
    }

    repo_1.push

    repo_2[:countries].insert 'UY', name: 'Uruguay'
    repo_2.commit author: 'User 2', message: 'Commit 2'
    repo_2.current_commit.must_equal_index 'countries' => {
      'UY' => digest(name: 'Uruguay'),
    }

    patch = repo_2.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}}
    }

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina'),
      'UY' => digest(name: 'Uruguay')
    }

    repo_1[:countries].delete 'AR'
    repo_1.commit author: 'User 1', message: 'Commit 4'
    repo_1.current_commit.must_equal_index Hash.new

    repo_1.push

    repo_2[:countries].update 'AR', name: 'Argentina', number: 54
    repo_2.commit author: 'User 2', message: 'Commit 5'
    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'UY' => digest(name: 'Uruguay')
    }

    patch = repo_2.pull
    delta = patch.delta
    delta.must_be_empty

    repo_2.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'UY' => digest(name: 'Uruguay')
    }

    repo_2.push

    patch = repo_1.pull
    delta = patch.delta
    delta.must_equal 'countries' => {
      'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina', 'number' => 54}},
      'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}},
    }

    repo_1.current_commit.must_equal_index 'countries' => {
      'AR' => digest(name: 'Argentina', number: 54),
      'UY' => digest(name: 'Uruguay')
    }
  end

end