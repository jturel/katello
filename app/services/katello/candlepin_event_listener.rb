module Katello
  class CandlepinEventListener
#    include Singleton

    # @pid need to be global....
    # is @pid necessarily a child process?

    def initialize(settings = SETTINGS[:katello][:candlepin_events])
      @settings = settings.merge(
        ssl_key_file: Setting[:ssl_priv_key],
        ssl_cert_file: Setting[:ssl_certificate],
        ssl_ca_file: Setting[:ssl_ca_file]
      )
      @settings.each do |key, value|
        ENV["candlepin_events_#{key}"] = value.to_s
      end
      @script = ::Katello::Engine.root.join('bin', 'candlepin_events')
    end

    def start
      raise "nope" if running?

      @pid = Process.spawn(@script.to_s)

      at_exit do
        stop
      end

      @pid
    end

    def stop
      if running?
        Rails.logger.info "closing"
        begin
          Process.kill('TERM', @pid)
        rescue Errno::ESRCH
          Rails.logger.info "process already done"
        end
      end
    end

    def running?
      # sometimes this returns true after defunct?
      begin
        Process.waitpid(@pid, Process::WNOHANG)
        true
      rescue Errno::ECHILD, TypeError
        false
      end
    end

    def self.handle_message(message)
      ::Katello::Util::Support.with_db_connection(logger) do
        subject = "#{message.headers['EVENT_TARGET']}.#{message.headers['EVENT_TYPE']}".downcase
        cp_event = Event.new(subject, message.body)
        ::Katello::Candlepin::EventHandler.new(logger).handle(cp_event)
      end
    rescue => e
      logger.error("Error handling Candlepin event")
      logger.error(e.message)
      logger.error(e.backtrace.join("\n"))
    end
  end
end
