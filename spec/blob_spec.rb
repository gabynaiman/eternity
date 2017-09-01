require 'minitest_helper'

describe Blob do

  let(:data) { {'id' => 'AR', 'name' => 'Argentina'} }
  let(:serialization) { MessagePack.pack data }
  let(:sha1) { Digest::SHA1.hexdigest serialization }
  let(:key) { Eternity.keyspace[:blob][:xyz][sha1] }
  let(:filename) { File.join(Eternity.blob_path, 'xyz', sha1[0..1], sha1[2..-1]) }

  def encode(text)
    Base64.encode64 text
  end

  def decode(text)
    Base64.decode64 text
  end

  def wait_and_read_file(filename)
    Timeout.timeout(5) do
      until File.exist?(filename) && File.size(filename) > 0
        sleep 0.001
      end
      IO.read filename
    end
  rescue Timeout::Error
    raise "File not found: #{filename}"
  end

  def with_cache_size(limit)
    blob_cache_max_size = Eternity.blob_cache_max_size
    Eternity.blob_cache_max_size = limit
    yield
  ensure
    Eternity.blob_cache_max_size = blob_cache_max_size
  end

  it 'Write in redis and file system' do
    sha1 = Blob.write :xyz, data

    redis_data = connection.call 'GET', key
    file_data = wait_and_read_file filename

    [redis_data, decode(file_data)].each { |d| MessagePack.unpack(d).must_equal data }
  end

  it 'Write only in file system' do
    with_cache_size 0 do
      sha1 = Blob.write :xyz, data

      redis_data = connection.call 'GET', key
      redis_data.must_be_nil

      file_data = wait_and_read_file filename
      MessagePack.unpack(decode(file_data)).must_equal data
    end
  end

  it 'Read from redis' do
    connection.call 'SET', key, serialization
    
    refute File.exist?(filename)
    Blob.read(:xyz, sha1).must_equal data
  end

  it 'Read from file' do
    FileUtils.mkpath File.dirname(filename)
    File.write filename, encode(serialization)

    connection.call('GET', key).must_be_nil
    Blob.read(:xyz, sha1).must_equal data
  end

  it 'Read invalid sha1' do
    error = proc { Blob.read :xyz, 'invalid_sha1' }.must_raise RuntimeError
    error.message.must_equal 'Blob not found: xyz -> invalid_sha1'
  end

  it 'Cache size' do
    Blob.cache_size.must_equal 0

    3.times { |i| Blob.write :xyz, value: i }

    Blob.cache_size.must_equal 3
  end

  it 'Clear cache' do
    3.times { |i| Blob.write :xyz, value: i }

    Blob.clear_cache

    Blob.cache_size.must_equal 0
  end

  it 'Normalize serialization' do
    time = Time.now
    data_1 = {key_1: 1, key_2: time}
    data_2 = {key_2: time.utc.strftime(TIME_FORMAT), key_1: 1}

    Blob.serialize(data_1).must_equal Blob.serialize(data_2)
  end

end