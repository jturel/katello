module Katello
  module Authorization::ProductContent
    extend ActiveSupport::Concern

    include Authorizable

    def readable?
      authorized?(:view_subscription)
    end

    module ClassMethods
      def readable
        authorized(:view_subscription)
      end
    end
  end
end
