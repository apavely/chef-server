require 'eventmachine'
require 'amqp'
require 'mq'
require 'opscode/expander/loggable'

module Opscode
  module Expander
    class VNode
      include Loggable

      attr_reader :vnode_number

      attr_reader :supervise_interval

      def initialize(vnode_number, opts={})
        @vnode_number = vnode_number
        @queue = nil
        @stopped = false
        @supervise_interval = opts[:supervise_interval] || 1
      end

      def start
        queue.subscribe(:ack => true) do |headers, payload|
          log.info  {"RCVD: queue(#{queue_name}); size(#{payload.size} bytes); time(#{Time.now.to_i});"}
          log.debug {"got #{payload} on queue #{queue_name}"}
          headers.ack
        end
        supervise_consumer_count
      end

      def supervise_consumer_count
        EM.add_periodic_timer(supervise_interval) do
          queue.status do |message_count, subscriber_count|
            if subscriber_count.to_i > 1
              log.error { "Detected extra consumers (#{subscriber_count} total) on queue #{queue_name}, cancelling subscription" }
              stop
            end
          end
        end
      end

      def stop
        log.info {"Cancelling subscription on queue #{queue_name.inspect}"}
        queue.unsubscribe
        @stopped = true
      end

      def stopped?
        @stopped
      end

      def queue
        Mutex.new.synchronize do
          return @queue if @queue

          log.debug { "declaring queue #{queue_name}" }
          @queue = MQ.queue(queue_name, :passive => false, :durable => false)
          log.debug { "binding queue #{queue_name} to exchange #{TOPIC_EXCHANGE} with key #{binding_key}"}
          @queue.bind(TOPIC_EXCHANGE, :key => binding_key)
          @queue
        end
      end

      def queue_name
        "vnode_#{@vnode_number}"
      end

      def binding_key
        "*.#{queue_name}"
      end

    end
  end
end