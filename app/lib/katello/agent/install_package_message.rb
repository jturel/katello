module Katello
  module Agent
    class InstallPackageMessage
      attr_reader :host_id, :consumer_id, :packages, :content_type

      def initialize(host_id:, packages:, consumer_id:, content_type:)
        @host_id = host_id
        @packages = packages
        @consumer_id = consumer_id
        @content_type = content_type
      end

      def json
        {
          data: {
            consumer_id: consumer_id
          },
          replyto: "pulp.task",
          request: {
            args: [
              [
                {
                  type_id: "rpm",
                  unit_key: {name: "screen"}
                }
              ],
              {
                importkeys: true
              }
            ],
            classname: "Content",
            cntr: [[], {}],
            kws: {},
            method: "uninstall"
          },
          routing: [
            nil,
            "pulp.agent.#{consumer_id}"
          ],
          version: "2.0"
        }
      end

      def content
        json.to_json
      end
    end
  end
end
