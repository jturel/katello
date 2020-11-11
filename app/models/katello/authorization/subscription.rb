module Katello
  module Authorization::Subscription
    extend ActiveSupport::Concern

    include Authorizable

    def readable?
      authorized?(:view_subscriptions)
    end

    module ClassMethods
      def readable
        authorized(:view_subscriptions)
      end

      def editable
        authorized(:import_manifest)
      end
    end
  end
end
