module Katello
  module Agent
    class InstallPackageMessage < BaseMessage
      def initialize(packages:, consumer_id:)
        @packages = packages
        @consumer_id = consumer_id
        @content_type = 'rpm'
        @method = 'install'
        super()
      end
    end
  end
end
