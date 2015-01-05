require 'minitest_helper'

describe 'Blob' do

  let(:data) { {'id' => 'AR', 'name' => 'Argentina'} }
  let(:serialization) { MessagePack.pack data }
  let(:sha1) { Digest::SHA1.hexdigest serialization }
  let(:key) { Eternity.keyspace[:blob][:xyz][sha1] }
  let(:filename) { File.join(Eternity.data_path, 'blob', 'xyz', sha1[0..1], sha1[2..-1]) }

  def wait_and_read_file(filename)
    Timeout.timeout(5) do
      until File.exists?(filename) && File.size(filename) > 0
        sleep 0.001
      end
      IO.read filename
    end
  rescue Timeout::Error
    raise "File not found: #{filename}"
  end

  it 'Write in redis and file system' do
    sha1 = Blob.write :xyz, data

    redis_data = redis.call 'GET', key
    file_data = wait_and_read_file filename

    [redis_data, file_data].each { |d| MessagePack.unpack(d).must_equal data }
  end

  it 'Read from redis' do
    redis.call 'SET', key, serialization
    
    refute File.exists?(filename)
    Blob.read(:xyz, sha1).must_equal data
  end

  it 'Read from file' do
    FileUtils.mkpath File.dirname(filename)
    File.write filename, serialization

    redis.call('GET', key).must_be_nil
    Blob.read(:xyz, sha1).must_equal data
  end

  it 'Read invalid sha1' do
    error = proc { Blob.read :xyz, 'invalid_sha1' }.must_raise RuntimeError
    error.message.must_equal 'Blob not found. Xyz: invalid_sha1'
  end

end