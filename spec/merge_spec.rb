require 'minitest_helper'

describe Repository, 'Merge' do

  let(:repo_1) { Repository.new :test_1 }
  let(:repo_2) { Repository.new :test_2 }
  let(:repo_3) { Repository.new :test_3 }

  let(:commits) { Hash.new }

  def commit(id, repo, &block)
    repo[:countries].instance_eval &block
    commits[id] = repo.commit author: repo.name, message: "Commit #{id}"
  end

  def merge(id, repo, target_id)
    delta = repo.merge commit: commits[target_id].id
    commits[id] = repo.current_commit
    yield delta['countries'] if block_given?
    delta
  end

  def assert_history(id, history_ids)
    commits[id].history.must_equal history_ids.map { |c| commits[c] }
  end

  def assert_index(id, expected)
    commits[id].must_equal_index 'countries' => expected
  end

  it 'Delta, index and history' do
    # REPO 1: (*)---(1)--(2)--(5)---(6)---(9)--(11)
    #                  \          /     \       /
    # REPO 2:           -(3)---(4)--(7)--(8)--(10)

    commit 1, repo_1 do
      insert 'AR', name: 'Argentina'
      insert 'BR', name: 'Brasil'
    end

    assert_history 1, []
    assert_index 1, 'AR' => digest(name: 'Argentina'),
                    'BR' => digest(name: 'Brasil')
    
    commit 2, repo_1 do
      delete 'BR'
    end

    assert_history 2, [1]
    assert_index 2, 'AR' => digest(name: 'Argentina')

    repo_2.checkout commit: commits[1].id

    commit 3, repo_2 do
      insert 'UY', name: 'Uruguay'
    end

    assert_history 3, [1]
    assert_index 3, 'AR' => digest(name: 'Argentina'),
                    'BR' => digest(name: 'Brasil'),
                    'UY' => digest(name: 'Uruguay')

    commit 4, repo_2 do
      update 'BR', name: 'Brasil', number: 55
    end

    assert_history 4, [3,1]
    assert_index 4, 'AR' => digest(name: 'Argentina'),
                    'BR' => digest(name: 'Brasil', number: 55),
                    'UY' => digest(name: 'Uruguay')

    commit 5, repo_1 do
      update 'AR', name: 'Argentina', number: 54
    end

    assert_history 5, [2, 1]
    assert_index 5, 'AR' => digest(name: 'Argentina', number: 54)

    merge 6, repo_1, 4 do |delta|
      delta.must_equal 'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}}
    end
    
    assert_history 6, [5,2,4,3,1]
    assert_index 6, 'AR' => digest(name: 'Argentina', number: 54),
                    'UY' => digest(name: 'Uruguay')

    commit 7, repo_2 do
      update 'AR', name: 'Argentina', code: 'ARG'
    end

    assert_history 7, [4,3,1]
    assert_index 7, 'AR' => digest(name: 'Argentina', code: 'ARG'),
                    'BR' => digest(name: 'Brasil', number: 55),
                    'UY' => digest(name: 'Uruguay')

    merge 8, repo_2, 6 do |delta|
      delta.must_equal 'BR' => {'action' => 'delete'}, 
                       'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG', 'number' => 54}}
    end
    
    assert_history 8, [7,6,5,2,4,3,1]
    assert_index 8, 'AR' => digest(name: 'Argentina', code: 'ARG', number: 54),
                    'UY' => digest(name: 'Uruguay')

    commit 9, repo_1 do
      insert 'CL', name: 'Chile', code: 'CHI'
    end

    assert_history 9, [6,5,2,4,3,1]
    assert_index 9, 'AR' => digest(name: 'Argentina', number: 54),
                    'UY' => digest(name: 'Uruguay'),
                    'CL' => digest(name: 'Chile', code: 'CHI')

    commit 10, repo_2 do
      insert 'CL', name: 'Republica de Chile', number: 56
    end

    assert_history 10, [8,7,6,5,2,4,3,1]
    assert_index 10, 'AR' => digest(name: 'Argentina', code: 'ARG', number: 54),
                     'UY' => digest(name: 'Uruguay'),
                     'CL' => digest(name: 'Republica de Chile', number: 56)

    merge 11, repo_1, 10 do |delta|
      delta.must_equal 'AR' => {'action' => 'update', 'data' => {'name' => 'Argentina', 'number' => 54, 'code' => 'ARG'}},
                       'CL' => {'action' => 'update', 'data' => {'name' => 'Chile', 'number' => 56, 'code' => 'CHI'}}
    end

    assert_history 11, [9,10,8,7,6,5,2,4,3,1]
    assert_index 11, 'AR' => digest(name: 'Argentina', code: 'ARG', number: 54),
                     'UY' => digest(name: 'Uruguay'),
                     'CL' => digest(name: 'Chile', number: 56, code: 'CHI')
  end

end