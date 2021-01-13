module Actions
  module Katello
    module Agent
      class DispatchHistoryPresenter < Helpers::Presenter::Base
        def initialize(action)
          @action = action
        end

        def humanized_output
          history_id = @action.output[:dispatch_history_id]

          if history_id
            dispatch_history = ::Katello::Agent::DispatchHistory.find_by_id(history_id)

            if dispatch_history&.status
              dispatch_history.status
            end
          end
        end
      end
    end
  end
end
