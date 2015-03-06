module Eternity
  module Log

    private

    def log(method)
      original_method = "__#{method}_without_log__"

      alias_method original_method, method

      define_method method do |*args, &block|
        Eternity.logger.info(self.class.name) { "#{method} (Start)" }
        result = send original_method, *args, &block
        Eternity.logger.info(self.class.name) { "#{method} (End)" }
        result
      end

      private original_method
    end

  end
end