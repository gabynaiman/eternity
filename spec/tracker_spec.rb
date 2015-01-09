require 'minitest_helper'

describe Tracker do

  let(:tracker) { Tracker.new Session.new(:test) }
  
  it 'Initial status' do
    tracker.must_be_empty
    tracker.flatten.must_be_empty
  end

  it 'Insert' do
    tracker[:countries].insert 'AR', name: 'Argentina'

    tracker.to_h.must_equal 'countries' => {'AR' => [{'event' => 'insert', 'blob' => digest(name: 'Argentina')}]}
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'insert', 'data' => {'name' => 'Argentina'}}}
  end

  it 'Insert -> Update' do
    tracker[:countries].insert 'AR', name: 'Argentina'
    tracker[:countries].update 'AR', name: 'Argentina', code: 'ARG'

    tracker.to_h.must_equal 'countries' => {'AR' => [
      {'event' => 'insert', 'blob' => digest(name: 'Argentina')},
      {'event' => 'update', 'blob' => digest(name: 'Argentina', code: 'ARG')}
    ]}
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'insert', 'data' => {'name' => 'Argentina', 'code' => 'ARG'}}}
  end

  it 'Insert -> Delete' do
    tracker[:countries].insert 'AR', name: 'Argentina'
    tracker[:countries].delete 'AR'

    tracker.to_h.must_equal 'countries' => {
      'AR' => [
        {'event' => 'insert', 'blob' => digest(name: 'Argentina')},
        {'event' => 'delete'}
      ]
    }
    tracker.flatten.must_be_empty
  end

  it 'Update' do
    tracker[:countries].update 'AR', name: 'Argentina', code: 'ARG'

    tracker.to_h.must_equal 'countries' => {'AR' => [{'event' => 'update', 'blob' => digest(name: 'Argentina', code: 'ARG')}]}
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG'}}}
  end

  it 'Update -> Delete' do
    tracker[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    tracker[:countries].delete 'AR'

    tracker.to_h.must_equal 'countries' => {
      'AR' => [
        {'event' => 'update', 'blob' => digest(name: 'Argentina', code: 'ARG')},
        {'event' => 'delete'}
      ]
    }
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'delete'}}
  end

  it 'Update -> Delete -> Insert' do
    tracker[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    tracker[:countries].delete 'AR'
    tracker[:countries].insert 'AR', name: 'Argentina'

    tracker.to_h.must_equal 'countries' => {
      'AR' => [
        {'event' => 'update', 'blob' => digest(name: 'Argentina', code: 'ARG')},
        {'event' => 'delete'},
        {'event' => 'insert', 'blob' => digest(name: 'Argentina')}
      ]
    }
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'update', 'data' => {'name' => 'Argentina'}}}
  end

  it 'Delete' do
    tracker[:countries].delete 'AR'

    tracker.to_h.must_equal 'countries' => {'AR' => [{'event' => 'delete'}]}
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'delete'}}
  end

  it 'Delete -> Insert' do
    tracker[:countries].delete 'AR'
    tracker[:countries].insert 'AR', name: 'Argentina'

    tracker.to_h.must_equal 'countries' => {
      'AR' => [
        {'event' => 'delete'},
        {'event' => 'insert', 'blob' => digest(name: 'Argentina')}
      ]
    }
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'update', 'data' => {'name' => 'Argentina'}}}
  end

  it 'Delete -> Insert -> Update' do
    tracker[:countries].delete 'AR'
    tracker[:countries].insert 'AR', name: 'Argentina'
    tracker[:countries].update 'AR', name: 'Argentina', code: 'ARG'

    tracker.to_h.must_equal 'countries' => {
      'AR' => [
        {'event' => 'delete'},
        {'event' => 'insert', 'blob' => digest(name: 'Argentina')},
        {'event' => 'update', 'blob' => digest(name: 'Argentina', code: 'ARG')}
      ]
    }
    tracker.flatten.must_equal 'countries' => {'AR' => {'event' => 'update', 'data' => {'name' => 'Argentina', 'code' => 'ARG'}}}
  end

  it 'Revert' do
    tracker[:countries].insert 'AR', name: 'Argentina'
    tracker[:countries].insert 'UY', name: 'Uruguay'

    tracker[:countries].revert 'AR'

    tracker.to_h.must_equal 'countries' => {'UY' => [{'event' => 'insert', 'blob' => digest(name: 'Uruguay')}]}
    tracker.flatten.must_equal 'countries' => {'UY' => {'event' => 'insert', 'data' => {'name' => 'Uruguay'}}}
  end

  it 'Revert all' do
    tracker[:countries].insert 'AR', name: 'Argentina'
    tracker[:cities].insert 'CABA', name: 'Ciudad Autonoma de Buenos Aires'

    tracker.revert

    tracker.must_be_empty
    tracker.flatten.must_be_empty
  end

end