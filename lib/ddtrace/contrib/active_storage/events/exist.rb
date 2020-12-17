require 'ddtrace/contrib/analytics'
require 'ddtrace/contrib/active_storage/event'
require 'ddtrace/ext/http'
require 'ddtrace/contrib/active_storage/ext'

module Datadog
  module Contrib
    module ActiveStorage
      module Events
        # Defines instrumentation for 'service_exist.active_storage' event.
        # From: https://edgeguides.rubyonrails.org/active_support_instrumentation.html#active-storage
        module Exist
          include ActiveStorage::Event

          EVENT_NAME = 'service_exist.active_storage'.freeze

          module_function

          def event_name
            self::EVENT_NAME
          end

          def span_name
            Ext::SPAN_ACTION
          end

          def span_type
            # Interacting with a cloud based image service
            Datadog::Ext::HTTP::TYPE_OUTBOUND
          end

          def resource_prefix
            Ext::ACTION_EXIST
          end

          def process(span, _event, _id, payload)
            as_key = payload[:key]
            as_service = payload[:service]
            as_exist = payload[:exist]

            span.service = configuration[:service_name]
            span.resource = "#{resource_prefix} #{as_service}"
            span.span_type = span_type

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
            end

            # Measure service stats
            Contrib::Analytics.set_measured(span)

            span.set_tag(Ext::TAG_SERVICE, as_service)
            span.set_tag(Ext::TAG_KEY, as_key)
            span.set_tag(Ext::TAG_EXIST, as_exist)
          end
        end
      end
    end
  end
end