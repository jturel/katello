module Katello
  module Middleware
    class EventDaemon
      def initialize(app)
        @app = app
      end

      def call(env)
        Rails.logger.info(self.object_id)
        unless @event_daemon_started
          Katello::EventDaemon::Runner.start
          @event_daemon_started = true
        end
        @app.call(env)
      end
    end
  end
end
