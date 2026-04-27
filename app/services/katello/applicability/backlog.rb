module Katello
  module Applicability
    class Backlog
      attr_reader :host_ids

      def initialize
        @host_ids = Set.new
      end

      def add(host_ids)
        @host_ids.merge(host_ids)
      end

      def remove(host_ids)
        @host_ids -= host_ids
      end

      def empty?
        @host_ids.empty?
      end

      def size
        @host_ids.size
      end
    end
  end
end
