module Katello
  module Middleware
    class EventDaemon
      def initialize(app)
        @app = app
      end

      def call(env)
        # middleware is not necessarily thread safe because
        # a single instance is created per process
        # setting this instance variable would ordinarily not be advised
        # but since Runner.start *is* thread safe, we can rely on that to
        # ensure the daemon is only started once, and that we dont repeatedly
        # hammer the Runner.start method which is relatively expensive
        unless @event_daemon_started
          Katello::EventDaemon::Runner.start
          @event_daemon_started = true
        end

        @app.call(env)
      end
    end
  end
end
