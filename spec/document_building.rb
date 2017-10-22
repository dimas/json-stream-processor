require 'stream_builder'

describe StreamBuilder do
  subject { StreamBuilder.new }

  it 'builds a string value' do
    subject.start_document
    subject.value("test")
    subject.end_document
    expect(subject.result).to eql("test")
  end

  it 'builds a bool value' do
    subject.start_document
    subject.value(true)
    subject.end_document
    expect(subject.result).to eql(true)
  end

  it 'builds a number value' do
    subject.start_document
    subject.value(24.0)
    subject.end_document
    expect(subject.result).to eql(24.0)
  end

  it 'builds a null value' do
    subject.start_document
    subject.value(nil)
    subject.end_document
    expect(subject.result).to eql(nil)
  end

  it 'builds an emtpy array' do
    subject.start_document
    subject.start_array
    subject.end_array
    subject.end_document
    expect(subject.result).to eql([])
  end

  it 'builds nested emtpy arrays' do
    subject.start_document
    subject.start_array
      subject.start_array
      subject.end_array
      subject.start_array
      subject.end_array
    subject.end_array
    subject.end_document
    expect(subject.result).to eql([[], []])
  end

  it 'builds an emtpy object' do
    subject.start_document
    subject.start_object
    subject.end_object
    subject.end_document
    expect(subject.result).to eql({})
  end

  it 'builds complex structure' do
    subject.start_document
    subject.start_object
      subject.key "key1"
      subject.value true
      subject.key "key2"
      subject.value "apple"
      subject.key "key3"
      subject.start_object
        subject.key "subkey1"
        subject.value "orange"
        subject.key "subkey2"
        subject.start_array
          subject.value "banana"
          subject.value true
          subject.value 10
        subject.end_array
      subject.end_object
      subject.key "key4"
      subject.start_array
        subject.value "kiwi"
        subject.value false
        subject.start_object
          subject.key "subkey2"
          subject.value "orange"
        subject.end_object
        subject.value nil
        subject.value 22.0
      subject.end_array
    subject.end_object
    subject.end_document

    expect(subject.result).to eql({
      "key1" => true,
      "key2" => "apple",
      "key3" => {
        "subkey1" => "orange",
        "subkey2" => ["banana", true, 10],
      },
      "key4" => ["kiwi", false, {"subkey2" => "orange"}, nil, 22.0]
    })
  end

end

