module Katello
  module Agent
    class BaseMessage
      attr_accessor :dispatch_history_id
      attr_reader :recipient_address

      def initialize
        @recipient_address = "pulp.agent.#{@consumer_id}"
      end

      def json
        {
          data: {
            consumer_id: @consumer_id,
            dispatch_history_id: self.dispatch_history_id
          },
          replyto: "pulp.task",
          request: {
            args: [
              self.units,
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
        json.to_json
      end
    end
  end
end
