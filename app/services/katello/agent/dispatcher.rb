module Katello
  module Agent
    class Dispatcher
      include Katello::Agent::Connection

      def self.install_package(host_id:, consumer_id:, packages:, content_type: 'rpm')
        message = Katello::Agent::InstallPackageMessage.new(
          host_id: host_id,
          consumer_id: consumer_id,
          packages: packages,
          content_type: content_type
        )

        dispatch(message) do |message, history|
          history.host_id = host_id
          yield(message, history) if block_given?
        end
      end

      def self.dispatch(message)
        ActiveRecord::Base.transaction do
          history = Katello::Agent::DispatchHistory.new
          yield(message, history) if block_given?
          history.save!
          send_message(message, history)
          history
        end
      end
    end
  end
end
