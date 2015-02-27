module Eternity
  class Blob

    attr_reader :type, :sha1

    def initialize(type, sha1)
      @type = type
      @sha1 = sha1
    end

    def data
      sha1 ? Blob.read(type, sha1) : {}
    end

    class << self
  
      def write(type, data)
        serialization = serialize data
        sha1 = digest serialization

        write_redis type, sha1, serialization
        write_file type, sha1, serialization

        sha1
      end

      def read(type, sha1)
        deserialize read_redis(type, sha1) || read_file(type, sha1)
      end

      def digest(string)
        Digest::SHA1.hexdigest string
      end

      def serialize(data)
        MessagePack.pack normalize(data)
      end

      def deserialize(string)
        MessagePack.unpack string
      end

      def clear_cache
        Eternity.redis.call('KEYS', Eternity.keyspace[:blob]['*']).each_slice(1000) do |keys|
          Eternity.redis.call 'DEL', *keys
        end
      end

      def count
        Eternity.redis.call('KEYS', Eternity.keyspace[:blob]['*']).count
      end

      private

      def normalize(data)
        sorted_data = Hash[data.sort_by { |k,v| k.to_s }]
        sorted_data.each { |k,v| sorted_data[k] = v.utc.strftime TIME_FORMAT if v.respond_to? :utc }
      end

      def write_redis(type, sha1, serialization)
        Eternity.redis.call 'SET', Eternity.keyspace[:blob][type][sha1], serialization, 
                            'EX', Eternity.blob_cache_expiration
      end

      def read_redis(type, sha1)
        Eternity.redis.call 'GET', Eternity.keyspace[:blob][type][sha1]
      end

      def write_file(type, sha1, serialization)
        filename = file_for type, sha1
        if !File.exists? filename
          dirname = File.dirname filename
          FileUtils.mkpath dirname unless Dir.exists? dirname
          File.write filename, Base64.encode64(serialization)
        end
      end

      def read_file(type, sha1)
        serialization = Base64.decode64(IO.read(file_for(type, sha1)))
        write_redis type, sha1, serialization
        serialization

      rescue Errno::ENOENT
        raise "Blob not found: #{type} -> #{sha1}"
      end

      def file_for(type, sha1)
        File.join Eternity.blob_path, type.to_s, sha1[0..1], sha1[2..-1]
      end

    end
    
  end
end