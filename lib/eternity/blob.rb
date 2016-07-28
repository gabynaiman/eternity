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

      def normalize(data)
        case data
          when Hash
            sorted_data = Hash[data.sort_by { |k,v| k.to_s }]
            sorted_data.each { |k,v| sorted_data[k] = v.utc.strftime TIME_FORMAT if v.respond_to? :utc }
          when Array
            data.map { |d| normalize d }
          else
            data
        end
      end

      def clear_cache
        Eternity.connection.call('KEYS', Eternity.keyspace[:blob]['*']).each_slice(1000) do |keys|
          Eternity.connection.call 'DEL', *keys
        end
      end

      def count
        Eternity.connection.call('KEYS', Eternity.keyspace[:blob]['*']).count
      end

      def orphan_files
        repositories = Repository.all
        
        repo_commits = repositories.map { |r| r.current_commit } + 
                       repositories.flat_map { |r| r.branches.values.map { |c| Commit.new c } }
        
        branch_commits = Branch.names.map { |b| Branch[b] }

        used_by_type = {
          commit: (repo_commits.flat_map { |c| [c.id] + c.history_ids } + branch_commits.flat_map { |c| [c.id] + c.history_ids }).uniq
        }

        commit_blobs = used_by_type[:commit].map { |id| Blob.read :commit, id }

        [:index, :delta, :history].each do |type|
          used_by_type[type] = commit_blobs.map { |b| b[type.to_s] }.compact
        end

        used_by_type.each_with_object({}) do |(type, used), hash|
          hash[type] = files_of(type) - used.map { |id| file_for type, id }
        end
      end

      private

      def write_redis(type, sha1, serialization)
        if serialization.size <= Eternity.blob_cache_max_size
          Eternity.connection.call 'SET', Eternity.keyspace[:blob][type][sha1], serialization, 
                                   'EX', Eternity.blob_cache_expiration
        end
      end

      def read_redis(type, sha1)
        Eternity.connection.call 'GET', Eternity.keyspace[:blob][type][sha1]
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

      def files_of(type)
        Dir.glob File.join(Eternity.blob_path, type.to_s, '*', '*')
      end

    end
    
  end
end