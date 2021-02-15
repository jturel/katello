module Katello
  module EventDaemon
    class Monitor
      def initialize(services)
        @service_registry = {}
        @service_statuses = {}
        services.each do |name, klass|
          @service_registry[name] = {
            class: klass,
            instance: nil,
            thread: nil
          }
        end
      end

      def start
        loop do
          break if @stop

          Rails.application.executor.wrap do
            check_services
            write_statuses_to_cache
          end

          sleep 2
        end
      end

      def stop
        @stop = true
      end

      def stop_services
        @service_registry.each do |service_name, service|
          stop_service(service_name, service)
        rescue => e
          Rails.logger.error("error while closing #{service_name}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      def write_statuses_to_cache
        Rails.cache.write(
          Katello::EventDaemon::Runner::STATUS_CACHE_KEY,
          @service_statuses,
          expires_in: 1.minute
        )
      end

      def start_service(service_name, service_class)
        instance = service_class.new
        @service_registry[service_name][:instance] = instance
        if service_class.try(:blocking)
          @service_registry[service_name][:thread] = Thread.new do
            instance.run
          end
        else
          instance.run
        end
        Rails.logger.info("Started #{service_name}")
        sleep 0.1 # give time for service to start so first cache will show running state
        instance
      end

      def stop_service(service_name, service)
        service[:instance]&.close
        # add a comment here if we really need to do this
        service[:instance] = nil
        service[:thread]&.join
        Rails.logger.info("Closed #{service_name}")
      end

      def service_running?(service_name)
        @service_statuses.dig(service_name, :running) == true
      end

      def check_services
        @service_registry.each do |service_name, service|
          instance = service[:instance] || start_service(service_name, service[:class])
          @service_statuses[service_name] = instance.status
        rescue => error
          Rails.logger.error("Error occurred pinging #{service_name}: #{error.message}")
          Rails.logger.error(error.backtrace.join("\n"))
        ensure
          # checks error here because updating status may have failed and cache is now inaccurate
          # should this rescue errors?
          stop_service(service_name, service) if error || !service_running?(service_name)
        end
      end
    end
  end
end
