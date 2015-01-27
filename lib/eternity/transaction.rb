module Eternity
  class Transaction
  
    def self.execute
      Restruct::Batch.execute(Eternity.redis) do
        ActiveRecord::Base.transaction do
          yield
        end
      end
    end

  end
end