require 'minitest_helper'

describe Session do

  let(:session) { Session.new :test_1 }
  let(:other_repository) { Repository.new :test_2 }

  describe 'Pull' do

    it 'Synchronize -> insert' do
      attributes = {id: SecureRandom.uuid, name: 'Spanish', created_at: Time.new.at_midnight, updated_at: Time.new.at_midnight}

      other_repository.tap do |repo|
        repo[:languages].insert attributes[:id], attributes
        repo.commit author: repo.name, message: "Insert: #{attributes[:name]}"
        repo.push
      end

      Language.count.must_equal 0

      session.pull

      session.current_commit.id.must_equal other_repository.current_commit.id

      Language.count.must_equal 1
      language = Language.find attributes[:id]
      attributes.each do |name, value|
        language.public_send(name).must_equal value
      end
    end
    
    it 'Synchronize -> update' do
      attributes = {name: 'Spanish', created_at: Time.new.at_midnight, updated_at: Time.new.at_midnight}

      Session.with :test_1 do
        language = Language.create! attributes
        attributes.merge! id: language.id
      end

      session.commit author: session.name, message: "Insert: #{attributes[:name]}"
      session.push

      other_repository.tap do |repo|
        repo.pull
        repo[:languages].update attributes[:id], attributes.merge!(name: 'English')
        repo.commit author: repo.name, message: "Update: #{attributes[:name]}"
        repo.push
      end

      session.pull

      Language.count.must_equal 1

      language = Language.find attributes[:id]
      attributes.each do |name, value|
        language.public_send(name).must_equal value
      end
    end
    
    it 'Synchronize -> delete' do
      attributes = {name: 'Spanish', created_at: Time.new.at_midnight, updated_at: Time.new.at_midnight}

      Session.with :test_1 do
        language = Language.create! attributes
        attributes.merge! id: language.id
      end

      session.commit author: session.name, message: "Insert: #{attributes[:name]}"
      session.push

      other_repository.tap do |repo|
        repo.pull
        repo[:languages].delete attributes[:id]
        repo.commit author: repo.name, message: "Delete: #{attributes[:name]}"
        repo.push
      end

      session.pull

      Language.count.must_equal 0
    end

  end
  
end