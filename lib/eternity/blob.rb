module Eternity
  class Blob
  
    def self.write(type, data)
      serialization = serialize data
      sha1 = digest serialization

      write_redis type, sha1, serialization
      Thread.new { write_file type, sha1, serialization }

      sha1
    end

    def self.read(type, sha1)
      deserialize read_redis(type, sha1) || read_file(type, sha1)
    end

    def self.digest(string)
      Digest::SHA1.hexdigest string
    end

    def self.serialize(data)
      MessagePack.pack data
    end

    def self.deserialize(string)
      MessagePack.unpack string
    end

    private

    def self.write_redis(type, sha1, serialization)
      Eternity.redis.call 'SET', Eternity.keyspace[:blob][type][sha1], serialization, 
                          'EX', Eternity.blob_cache_expiration
    end

    def self.read_redis(type, sha1)
      Eternity.redis.call 'GET', Eternity.keyspace[:blob][type][sha1]
    end

    def self.write_file(type, sha1, serialization)
      filename = file_for type, sha1
      if !File.exists? filename
        dirname = File.dirname filename
        FileUtils.mkpath dirname unless Dir.exists? dirname
        File.write filename, serialization
      end
    end

    def self.read_file(type, sha1)
      serialization = IO.read file_for(type, sha1)
      Thread.new { write_redis type, sha1, serialization }
      serialization

    rescue Errno::ENOENT
      raise "Blob not found. #{type.capitalize}: #{sha1}"
    end

    def self.file_for(type, sha1)
      File.join Eternity.data_path, 'blob', type.to_s, sha1[0..1], sha1[2..-1]
    end
  
  end
end