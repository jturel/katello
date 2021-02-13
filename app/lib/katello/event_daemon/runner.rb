module Katello
  module EventDaemon
    class Runner
      STATUS_CACHE_KEY = "katello_event_daemon_status".freeze
      @services = {}

      class << self
        def initialize
          FileUtils.touch(lock_file)
        end

        def settings
          SETTINGS[:katello][:event_daemon]
        end

        def pid
          return unless pid_file && File.exist?(pid_file)

          File.open(pid_file) { |f| f.read.to_i }
        end

        def pid_file
          pid_dir.join('katello_event_daemon.pid')
        end

        def pid_dir
          Rails.root.join('tmp', 'pids')
        end

        def lock_file
          Rails.root.join('tmp', 'katello_event_daemon.lock')
        end

        def write_pid_file
          return unless pid_file

          FileUtils.mkdir_p(pid_dir)
          File.open(pid_file, 'w') { |f| f.puts Process.pid }
        end

        def stop
          return unless pid == Process.pid
          @monitor&.stop
          @monitor&.stop_services
          @monitor_thread&.join if Thread.current != @monitor_thread
          File.unlink(pid_file) if pid_file && File.exist?(pid_file)
        end

        def start
          File.open(lock_file, 'r') do |lockfile|
            lockfile.flock(File::LOCK_EX)
            unless started? # may have been started in another process while we waited for the lock
              write_pid_file
              start_monitor_thread

              at_exit do
                stop
              end

              Rails.logger.info("Katello event daemon started process=#{Process.pid}")
            end
          ensure
            lockfile.flock(File::LOCK_UN)
          end
        end

        def started?
          Process.kill(0, pid)
          true
        rescue Errno::ESRCH, TypeError # process no longer exists
          false
        end

        def start_monitor
          @monitor = Katello::EventDaemon::Monitor.new(@services)
          @monitor.start
        rescue => e
          Rails.logger.error("Error in monitor thread. Stopping daemon!")
          Rails.logger.error(e.message)
          self.stop
          self.start
        end

        def start_monitor_thread
          @monitor_thread = Thread.new do
            start_monitor
          end
        end

        def register_service(name, klass)
          @services[name] = klass
        end

        def service_status(service_name)
          Rails.cache.read(STATUS_CACHE_KEY)&.dig(service_name)
        end
      end
    end
  end
end
