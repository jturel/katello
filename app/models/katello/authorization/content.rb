module Katello
  module Authorization::Content
    extend ActiveSupport::Concern

    def readable?
      authorized?(:view_subscription)
    end

    def editable?
      authorized?(:import_manifest)
    end

    module ClassMethods
      def readable
        authorized(:view_subscription)
      end

      def editable
        authorized(:import_manifest)
      end
    end
  end
end
