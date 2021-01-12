module Katello
  module Agent
    class RemovePackageMessage < BaseMessage
      def initialize(packages:, consumer_id:)
        @packages = packages
        @consumer_id = consumer_id
        @content_type = 'rpm'
        @method = 'uninstall'
        super()
      end
    end
  end
end
