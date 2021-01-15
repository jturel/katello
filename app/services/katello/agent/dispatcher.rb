module Katello
  module Agent
    class Dispatcher
      include Katello::Agent::Connection

      def self.install_package(host_id:, packages:)
        message = Katello::Agent::InstallPackageMessage.new(
          host_id: host_id,
          packages: packages
        )

        dispatch(message)
      end

      def self.remove_package(host_id:, packages:)
        message = Katello::Agent::RemovePackageMessage.new(
          host_id: host_id,
          packages: packages
        )

        dispatch(message)
      end

      def self.install_errata(host_id:, errata_ids:)
        message = Katello::Agent::InstallErrataMessage.new(
          host_id: host_id,
          errata_ids: errata_ids
        )

        dispatch(message)
      end

      def self.dispatch(message)
        history = Katello::Agent::DispatchHistory.new
        history.host_id = message.host_id
        history.save!
        message.dispatch_history_id = history.id
        send_message(message)
        history
      end
    end
  end
end
