require 'minitest_helper'

describe Patch do

  let(:repo_1) { Repository.new :test_1 }
  let(:repo_2) { Repository.new :test_2 }
  let(:repo_3) { Repository.new :test_3 }
  let(:commits) { Hash.new }

  before do
    # Repo 1: X---(1)---(2)---(3)---(4)---(5)---(8)---(9)---(12)---(13)---(14)
    # Repo 2:  \                 \--(6)---(7)--/           /
    # Repo 3:   \----------(10)-----------------(11)------/

    repo_1[:countries].insert 'AR', name: 'Argentina'
    commit repo_1, 1

    repo_1[:countries].insert 'UY', name: 'Uruguay'
    commit repo_1, 2

    repo_1[:countries].insert 'BR', name: 'Brasil'
    commit repo_1, 3
    repo_1.push

    repo_1[:countries].update 'UY', name: 'Republica Oriental del Uruguay'
    commit repo_1, 4

    repo_1[:countries].update 'AR', name: 'Argentina', number: 54
    commit repo_1, 5

    repo_2.pull
    repo_2[:countries].insert 'CL', name: 'Chile'
    commit repo_2, 6

    repo_2[:countries].update 'AR', name: 'Republica Argentina'
    commit repo_2, 7
    repo_2.push

    repo_1.pull
    add_commit repo_1.current_commit, 8

    repo_1[:countries].delete 'CL'
    commit repo_1, 9
    repo_1.push

    repo_3[:countries].insert 'CO', name: 'Colombia'
    commit repo_3, 10

    repo_3[:countries].update 'CO', name: 'Colombia', number: 57
    commit repo_3, 11

    repo_1.merge commit: commits[11].id
    add_commit repo_1.current_commit, 12

    repo_1[:countries].update 'BR', name: 'Brasil', number: 55
    commit repo_1, 13

    repo_1[:countries].delete 'CO'
    commit repo_1, 14
  end

  def commit(repo, index)
    commits[index] = repo.commit author: repo.name, message: "Commit #{index}"
  end

  def add_commit(commit, index)
    commits[index] = commit
  end

  describe 'Same commit' do

    it 'Merge' do
      patch = Patch.merge commits[4], commits[4]

      patch.delta.must_be_empty
      patch.base_commit.must_equal commits[4]
      patch.base_delta.must_be_empty
    end

    it 'Diff' do
      patch = Patch.diff commits[4], commits[4]

      patch.delta.must_be_empty
      patch.base_commit.must_equal commits[4]
    end

  end

  describe 'Both initial commits' do

    it 'Merge' do
      patch = Patch.merge commits[1], commits[11]

      patch.delta.must_equal 'countries' => {
        'CO' => {'action' => 'insert', 'data' => {'name' => 'Colombia', 'number' => 57}}
      }
      patch.base_commit.must_be_nil
      patch.base_delta.must_equal 'countries' => {
        'AR' => {'action' => 'insert', 'data' => {'name' => 'Argentina'}},
        'CO' => {'action' => 'insert', 'data' => {'name' => 'Colombia', 'number' => 57}}
      }
    end

    it 'Diff' do
      patch = Patch.diff commits[1], commits[11]

      patch.delta.must_equal 'countries' => {
        'AR' => {'action' => 'delete'},
        'CO' => {'action' => 'insert', 'data' => {'name' => 'Colombia', 'number' => 57}}
      }
      patch.base_commit.must_be_nil
    end

  end

  describe 'Fast forward' do

    it 'Merge' do
      patch = Patch.merge commits[1], commits[3]

      patch.delta.must_be_empty
      patch.base_commit.must_equal commits[1]
      patch.base_delta.must_be_empty
    end

    it 'Diff' do
      patch = Patch.diff commits[1], commits[3]

      patch.delta.must_equal 'countries' => {
        'UY' => {'action' => 'insert', 'data' => {'name' => 'Uruguay'}},
        'BR' => {'action' => 'insert', 'data' => {'name' => 'Brasil'}}
      }
      patch.base_commit.must_equal commits[1]
    end

  end

  describe 'Revert' do

    it 'Merge' do
      patch = Patch.merge commits[4], commits[2]

      patch.delta.must_be_empty
      patch.base_commit.must_equal commits[2]
      patch.base_delta.must_be_empty
    end

    it 'Diff' do
      patch = Patch.diff commits[4], commits[2]

      patch.delta.must_equal 'countries' => {
        'UY' => {'action' => 'update', 'data' => {'name' => 'Uruguay'}},
        'BR' => {'action' => 'delete'}
      }
      patch.base_commit.must_equal commits[2]
    end

  end

  describe 'Merge' do

    it 'Merge' do
      patch = Patch.merge commits[5], commits[7]
      
      patch.delta.must_equal 'countries' => {
        'AR' => {'action' => 'update', 'data' => {'name' => 'Republica Argentina', 'number' => 54}},
        'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
      }
      patch.base_commit.must_equal commits[3]
      patch.base_delta.must_equal 'countries' => {
        'UY' => {'action' => 'update', 'data' => {'name' => 'Republica Oriental del Uruguay'}},
        'AR' => {'action' => 'update', 'data' => {'name' => 'Republica Argentina', 'number' => 54}},
        'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}},
      }
    end

    it 'Diff' do
      patch = Patch.diff commits[5], commits[7]

      patch.delta.must_equal 'countries' => {
        'UY' => {'action' => 'update', 'data' => {'name' => 'Uruguay'}},
        'AR' => {'action' => 'update', 'data' => {'name' => 'Republica Argentina'}},
        'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
      }
      patch.base_commit.must_equal commits[3]
    end

  end

  describe 'Unmerge' do

    it 'Merge' do
      patch = Patch.merge commits[9], commits[7]

      patch.delta.must_be_empty
      patch.base_commit.must_equal commits[3]
      patch.base_delta.must_be_empty
    end

    it 'Diff' do
      patch = Patch.diff commits[9], commits[7]

      patch.delta.must_equal 'countries' => {
        'AR' => {'action' => 'update', 'data' => {'name' => 'Republica Argentina'}},
        'UY' => {'action' => 'update', 'data' => {'name' => 'Uruguay'}},
        'CL' => {'action' => 'insert', 'data' => {'name' => 'Chile'}}
      }
      patch.base_commit.must_equal commits[3]
    end

  end

end