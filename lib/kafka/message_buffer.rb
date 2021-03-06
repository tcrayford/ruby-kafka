require "kafka/protocol/message"

module Kafka

  # Buffers messages for specific topics/partitions.
  class MessageBuffer
    include Enumerable

    attr_reader :size, :bytesize

    def initialize
      @buffer = {}
      @size = 0
      @bytesize = 0
    end

    def write(value:, key:, topic:, partition:)
      message = Protocol::Message.new(key: key, value: value)

      buffer_for(topic, partition) << message

      @size += 1
      @bytesize += message.bytesize
    end

    def concat(messages, topic:, partition:)
      buffer_for(topic, partition).concat(messages)

      @size += messages.count
      @bytesize += messages.map(&:bytesize).reduce(:+)
    end

    def to_h
      @buffer
    end

    def empty?
      @buffer.empty?
    end

    def each
      @buffer.each do |topic, messages_for_topic|
        messages_for_topic.each do |partition, messages_for_partition|
          yield topic, partition, messages_for_partition
        end
      end
    end

    # Clears buffered messages for the given topic and partition.
    #
    # @param topic [String] the name of the topic.
    # @param partition [Integer] the partition id.
    #
    # @return [nil]
    def clear_messages(topic:, partition:)
      @size -= @buffer[topic][partition].count
      @bytesize -= @buffer[topic][partition].map(&:bytesize).reduce(:+)

      @buffer[topic].delete(partition)
      @buffer.delete(topic) if @buffer[topic].empty?
    end

    def message_count_for_partition(topic:, partition:)
      buffer_for(topic, partition).count
    end

    # Clears messages across all topics and partitions.
    #
    # @return [nil]
    def clear
      @buffer = {}
      @size = 0
    end

    private

    def buffer_for(topic, partition)
      @buffer[topic] ||= {}
      @buffer[topic][partition] ||= []
    end
  end
end
