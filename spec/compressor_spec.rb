describe Kafka::Compressor do
  describe ".compress" do
    it "encodes and decodes compressed messages" do
      compressor = Kafka::Compressor.new(codec_name: :snappy, threshold: 1)

      message1 = Kafka::Protocol::Message.new(value: "hello1")
      message2 = Kafka::Protocol::Message.new(value: "hello2")

      message_set = Kafka::Protocol::MessageSet.new(messages: [message1, message2])
      compressed_message_set = compressor.compress(message_set)

      data = Kafka::Protocol::Encoder.encode_with(compressed_message_set)
      decoder = Kafka::Protocol::Decoder.from_string(data)
      decoded_message = Kafka::Protocol::Message.decode(decoder)
      decoded_message_set = decoded_message.decompress

      expect(decoded_message_set.messages.map(&:value)).to eq ["hello1", "hello2"]
    end

    it "only compresses the messages if there are at least the configured threshold" do
      compressor = Kafka::Compressor.new(codec_name: :snappy, threshold: 3)

      message1 = Kafka::Protocol::Message.new(value: "hello1")
      message2 = Kafka::Protocol::Message.new(value: "hello2")

      message_set = Kafka::Protocol::MessageSet.new(messages: [message1, message2])
      compressed_message_set = compressor.compress(message_set)

      expect(compressed_message_set.messages).to eq [message1, message2]
    end

    it "reduces the data size" do
      compressor = Kafka::Compressor.new(codec_name: :snappy, threshold: 1)

      message1 = Kafka::Protocol::Message.new(value: "hello1" * 100)
      message2 = Kafka::Protocol::Message.new(value: "hello2" * 100)

      message_set = Kafka::Protocol::MessageSet.new(messages: [message1, message2])
      compressed_message_set = compressor.compress(message_set)

      uncompressed_data = Kafka::Protocol::Encoder.encode_with(message_set)
      compressed_data = Kafka::Protocol::Encoder.encode_with(compressed_message_set)

      expect(compressed_data.bytesize).to be < uncompressed_data.bytesize
    end
  end
end
