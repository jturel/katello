module Actions
  module Katello
    module Agent
      class DispatchHistoryPresenter
        def initialize(dispatch_history, action_type)
          @status = dispatch_history&.status&.with_indifferent_access
          @action_type = action_type
        end

        def humanized_output
          return unless @status

          result = extract_result
          ret = []

          if result
            if result.is_a?(String)
              ret << result
            else
              ret.concat(result.map { |package| package[:qname] })
            end
          else
            ret << humanized_no_package
          end

          ret.sort.join("\n")
        end

        private

        def extract_result
          @status.each do |k,v|
            if v[:succeeded] == true
              return v[:details][:resolved] + v[:details][:deps] 
            elsif v[:succeeded] == false
              return v[:message]
            end
          end

          nil
        end

        def humanized_no_package
          case @action_type
          when :content_install
            _("No new packages installed")
          when :content_uninstall
            _("No packages removed")
          end
        end
      end
    end
  end
end
