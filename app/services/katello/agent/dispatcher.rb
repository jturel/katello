module Katello
  module Agent
    class Dispatcher
      include Katello::Agent::Connection

      def self.install_package(host_id:, consumer_id:, packages:)
        message = Katello::Agent::InstallPackageMessage.new(
          consumer_id: consumer_id,
          packages: packages
        )

        dispatch(message) do |message, history|
          history.host_id = host_id
          yield(message, history) if block_given?
        end
      end

      def self.remove_package(host_id:, consumer_id:, packages:)
        message = Katello::Agent::RemovePackageMessage.new(
          consumer_id: consumer_id,
          packages: packages
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
          message.dispatch_history_id = history.id
          send_message(message)
          history
        end
      end
    end
  end
end
