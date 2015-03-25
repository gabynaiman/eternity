require 'minitest_helper'

describe Commit, 'history' do

  let(:repo_1) { Repository.new :test_1 }
  let(:repo_2) { Repository.new :test_2 }
  let(:repo_3) { Repository.new :test_3 }

  let(:commits) { Hash.new }

  def commit(repo, id)
    data = {id: SecureRandom.uuid}
    repo[:countries].insert data[:id], data
    commits[id] = repo.commit author: repo.name, message: "Commit #{id}"
  end

  def push(repo)
    repo.push
  end

  def pull(repo, merge_id=nil)
    repo.pull
    commits[merge_id] = repo.current_commit if merge_id
  end

  def assert_history(expected)
    commits.each do |i,c|
      c.history.must_equal expected[i].map { |e| commits[e] }, "Fail history of ##{i}: #{c}\nExpected: #{expected[i].map{ |c| commits[c].message }} \nActual: #{c.history.map(&:message)}"
    end
  end

  it 'Test 1' do
    #                    P          M     P
    # REPO 1: (*)--(1)--(2)--(4)---(6)---(7)
    #                    \        /        \
    # REPO 2:             -----(3)---(5)---(8)
    #                           P           M

    commit repo_1, 1
    commit repo_1, 2
    push   repo_1
    pull   repo_2
    commit repo_2, 3
    push   repo_2
    commit repo_1, 4
    commit repo_2, 5
    pull   repo_1, 6
    commit repo_1, 7
    push   repo_1
    pull   repo_2, 8

    assert_history 1 => [],
                   2 => [1],
                   3 => [2,1],
                   4 => [2,1],
                   5 => [3,2,1],
                   6 => [4,3,2,1],
                   7 => [6,4,3,2,1],
                   8 => [5,7,6,4,3,2,1]
  end

  it 'Test 2' do
    #               P                         M
    # REPO 1: (*)--(1)--(2)------------------(11)
    #               \             M    P     /
    # REPO 2:        --(3)--(4)--(7)--(8)   /
    #                \          /      \   /
    # REPO 3:         -(5)----(6)--(9)--(10)
    #                          P         MP

    commit repo_1, 1
    push   repo_1
    commit repo_1, 2
    pull   repo_2
    commit repo_2, 3
    commit repo_2, 4
    pull   repo_3
    commit repo_3, 5
    commit repo_3, 6
    push   repo_3
    pull   repo_2, 7
    commit repo_2, 8
    push   repo_2
    commit repo_3, 9
    pull   repo_3, 10
    push   repo_3
    pull   repo_1, 11

    assert_history 1  => [],
                   2  => [1],
                   3  => [1],
                   4  => [3,1],
                   5  => [1],
                   6  => [5,1],
                   7  => [4,3,6,5,1],
                   8  => [7,4,3,6,5,1],
                   9  => [6,5,1],
                   10 => [9,8,7,4,3,6,5,1],
                   11 => [2,10,9,8,7,4,3,6,5,1]
  end

end