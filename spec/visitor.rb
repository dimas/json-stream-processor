require 'stream_builder'

describe StreamBuilder do

  class CapturingBuilder < StreamBuilder

    attr_reader :visits

    def initialize
      @visits = []
    end

    def append(value)
      # Just remember context in which we were called and let superclass do the actual job
      @visits << {:value => value, :pos => pos, :path => path, :level => level }
      super
    end
  end

  subject { CapturingBuilder.new }

  it 'a value' do
    subject.start_document
    subject.value("test")
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 0, :path => [], :pos => nil, :value => "test" }
    ])
  end

  it 'an empty array' do
    subject.start_document
    subject.start_array
    subject.end_array
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 0, :path => [], :pos => nil, :value => [] }
    ])
  end

  it 'an array with values' do
    subject.start_document
    subject.start_array
      subject.value 100
    subject.end_array
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 1, :path => [0], :pos => 0,   :value => 100   },
      { :level => 0, :path => [],  :pos => nil, :value => [100] }
    ])
  end

  it 'nested arrays' do
    subject.start_document
    subject.start_array
      subject.start_array
        subject.value 100
      subject.end_array
      subject.value 200
    subject.end_array
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 2, :path => [0, 0], :pos => 0,   :value => 100          },
      { :level => 1, :path => [0],    :pos => 0,   :value => [100]        },
      { :level => 1, :path => [1],    :pos => 1,   :value => 200          },
      { :level => 0, :path => [],     :pos => nil, :value => [[100], 200] }
    ])
  end

  it 'an empty object' do
    subject.start_document
    subject.start_object
    subject.end_object
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 0, :path => [], :pos => nil, :value => {} }
    ])
  end

  it 'an object with values' do
    subject.start_document
    subject.start_object
      subject.key "k1"
      subject.value "avalue"
    subject.end_object
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 1, :path => ["k1"], :pos => "k1", :value => "avalue"           },
      { :level => 0, :path => [],     :pos => nil,  :value => {"k1" => "avalue"} }
    ])
  end

  it 'nested objects' do
    subject.start_document
    subject.start_object
      subject.key "k1"
      subject.value "avalue"
      subject.key "k2"
      subject.start_object
        subject.key "somekey"
        subject.value 1000
      subject.end_object
    subject.end_object
    subject.end_document

    expect(subject.visits).to eql([
      { :level => 1, :path => ["k1"],            :pos => "k1",      :value => "avalue"                                        },
      { :level => 2, :path => ["k2", "somekey"], :pos => "somekey", :value => 1000                                            },
      { :level => 1, :path => ["k2"],            :pos => "k2",      :value => {"somekey" => 1000}                             },
      { :level => 0, :path => [],                :pos => nil,       :value => {"k1" => "avalue", "k2" => {"somekey" => 1000}} }
    ])
  end

end

