module Katello
  module Agent
    class BaseMessage
      attr_reader :json
      attr_accessor :dispatch_history_id
      attr_reader :recipient_address

      def initialize
        @recipient_address = "pulp.agent.#{@consumer_id}"
        @json = {
          data: {
            consumer_id: @consumer_id
          },
          replyto: "pulp.task",
          request: {
            args: [
              [
                {
                  type_id: @content_type,
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
            method: @method
          },
          routing: [
            nil,
            @recipient_address
          ],
          version: "2.0"
        }
      end

      def to_s
        @json.to_json
      end
    end
  end
end
