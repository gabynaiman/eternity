require 'minitest_helper'

describe Index do

  let(:index) { Index.new }
  
  it 'Initial status' do
    index.must_be_empty
  end

  it 'Insert' do
    index[:countries].insert 'AR', name: 'Argentina'

    index.to_h.must_equal 'countries' => {'AR' => digest(name: 'Argentina')}
  end

  it 'Insert existent' do
    index[:countries].insert 'AR', name: 'Argentina'

    error = proc { index[:countries].insert 'AR', name: 'Argentina' }.must_raise RuntimeError
    error.message.must_equal 'Countries AR already exists'
  end

  it 'Insert -> Update' do
    index[:countries].insert 'AR', name: 'Argentina'
    index[:countries].update 'AR', name: 'Argentina', code: 'ARG'

    index.to_h.must_equal 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG')}
  end

  it 'Insert -> Delete' do
    index[:countries].insert 'AR', name: 'Argentina'
    index[:countries].insert 'UY', name: 'Uruguay'
    index[:countries].delete 'AR'

    index.to_h.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
  end

  it 'Insert -> Update -> Delete' do
    index[:countries].insert 'AR', name: 'Argentina'
    index[:countries].insert 'UY', name: 'Uruguay'
    index[:countries].update 'AR', name: 'Argentina', code: 'ARG'
    index[:countries].delete 'AR'

    index.to_h.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
  end

  it 'Update invalid' do
    error = proc { index[:countries].update 'INVALID', name: 'Invalid' }.must_raise RuntimeError
    error.message.must_equal 'Countries INVALID not found'
  end

  it 'Delete invalid' do
    error = proc { index[:countries].delete 'INVALID' }.must_raise RuntimeError
    error.message.must_equal 'Countries INVALID not found'
  end

  it 'Ids' do
    index[:countries].insert 'AR', name: 'Argentina'
    index[:countries].insert 'UY', name: 'Uruguay'

    index[:countries].ids.must_equal %w(AR UY)
  end

  it 'Write/Read blob' do
    index[:countries].insert 'AR', name: 'Argentina'
    index[:countries].insert 'UY', name: 'Uruguay'

    sha1 = index.write_blob
    index_2 = Index.read_blob sha1

    index.key.wont_equal index_2.key
    index.to_h.must_equal index_2.to_h
  end

end