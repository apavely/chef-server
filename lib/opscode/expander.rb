module Opscode
  module Expander

    # VNODES is the number of queues in rabbit that are available for subscribing.
    # The name comes from riak, where the data ring (160bits) is chunked into
    # many vnodes; vnodes outnumber physical nodes, so one node hosts several
    # vnodes. That is the same design we use here.
    #
    # See the notes on topic queue benchmarking before adjusting this value.
    VNODES = 1024

    TOPIC_EXCHANGE = "opscode-platform"

  end
end
