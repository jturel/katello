module Katello
  module EventDaemon
    class Monitor
      def initialize(service_classes)
        @service_classes = service_classes
      end

      def start
        error = nil
        status = nil
        loop do
          Rails.application.executor.wrap do
            check_services(error, status)
          end
          sleep 15
        end
      end

      def check_services(error, status)
        @service_classes.each do |service_class|
          status = service_class.status
        rescue => error
          Rails.logger.error("Error occurred while pinging #{service_class}")
          Rails.logger.error(error.message)
          Rails.logger.error(error.backtrace.join("\n"))
        ensure
          if error || !status&.dig(:running)
            begin
              service_class.close
              service_class.run
              service_class.status
            rescue => error
              Rails.logger.error("Error occurred while starting #{service_class}")
              Rails.logger.error(error.message)
              Rails.logger.error(error.backtrace.join("\n"))
            ensure
              error = nil
            end
          end
        end
      end
    end
  end
end
