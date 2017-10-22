require 'stream_builder'

describe StreamBuilder do
  subject { StreamBuilder.new }

  context "given not started document" do

    it 'accepts start_document' do
      expect { subject.start_document }.not_to raise_error
    end

    it 'rejects end_document' do
      expect { subject.end_document }.to raise_error "Illegal state - document not started"
    end

    it 'rejects start_object' do
      expect { subject.start_object }.to raise_error "Illegal state - document not started"
    end

    it 'rejects end_object' do
      expect { subject.end_object }.to raise_error "Illegal state - document not started"
    end

    it 'rejects start_array' do
      expect { subject.start_array }.to raise_error "Illegal state - document not started"
    end

    it 'rejects end_array' do
      expect { subject.end_array }.to raise_error "Illegal state - document not started"
    end

    it 'rejects key' do
      expect { subject.key "test" }.to raise_error "Illegal state - document not started"
    end

    it 'rejects value' do
      expect { subject.value "test" }.to raise_error "Illegal state - document not started"
    end

  end

  context "given started document" do

    before do
      subject.start_document
    end

    it 'rejects start_document' do
      expect { subject.start_document }.to raise_error "Illegal state - document already started"
    end

    it 'accepts end_document' do
      expect { subject.end_document }.not_to raise_error
    end

    it 'accepts start_object' do
      expect { subject.start_object }.not_to raise_error
    end

    it 'rejects end_object' do
      expect { subject.end_object }.to raise_error "Illegal state - unexpected object end, object not started"
    end

    it 'accepts start_array' do
      expect { subject.start_array }.not_to raise_error
    end

    it 'rejects end_array' do
      expect { subject.end_array }.to raise_error "Illegal state - unexpected array end"
    end

    it 'rejects key' do
      expect { subject.key "test" }.to raise_error "Illegal state - unexpected key, must be in object"
    end

    it 'accepts value' do
      expect { subject.value "test" }.not_to raise_error
    end

  end

  context "given started object" do

    before do
      subject.start_document
      subject.start_object
    end

    it 'rejects start_document' do
      expect { subject.start_document }.to raise_error "Illegal state - document already started"
    end

    it 'rejects end_document' do
      expect { subject.end_document }.to raise_error "Illegal state - unexpected end of document"
    end

    it 'rejects start_object' do
      expect { subject.start_object }.to raise_error "Illegal state - key expected"
    end

    it 'accepts end_object' do
      expect { subject.end_object }.not_to raise_error
    end

    it 'rejects start_array' do
      expect { subject.start_array }.to raise_error "Illegal state - key expected"
    end

    it 'rejects end_array' do
      expect { subject.end_array }.to raise_error "Illegal state - unexpected array end"
    end

    it 'accepts key' do
      expect { subject.key "test" }.not_to raise_error
    end

    it 'rejects value' do
      expect { subject.value "test" }.to raise_error "Illegal state - key expected"
    end

  end

  context "given started object and key given" do

    before do
      subject.start_document
      subject.start_object
      subject.key "test"
    end

    it 'rejects start_document' do
      expect { subject.start_document }.to raise_error "Illegal state - document already started"
    end

    it 'rejects end_document' do
      expect { subject.end_document }.to raise_error "Illegal state - unexpected end of document"
    end

    it 'accepts start_object' do
      expect { subject.start_object }.not_to raise_error
    end

    it 'rejects end_object' do
      expect { subject.end_object }.to raise_error "Illegal state - unexpected object end, a value expected"
    end

    it 'accepts start_array' do
      expect { subject.start_array }.not_to raise_error
    end

    it 'rejects end_array' do
      expect { subject.end_array }.to raise_error "Illegal state - unexpected array end"
    end

    it 'rejects key' do
      expect { subject.key "test" }.to raise_error "Illegal state - unexpected key, already set"
    end

    it 'accepts value' do
      expect { subject.value "test" }.not_to raise_error
    end

  end

  context "given started object and key+value given" do

    before do
      subject.start_document
      subject.start_object
      subject.key "test"
      subject.value "test"
    end

    # the test cases are just copy of "given started object" because the state after reading a key/value pair
    # inside object should be the same as before reading first

    it 'rejects start_document' do
      expect { subject.start_document }.to raise_error "Illegal state - document already started"
    end

    it 'rejects end_document' do
      expect { subject.end_document }.to raise_error "Illegal state - unexpected end of document"
    end

    it 'rejects start_object' do
      expect { subject.start_object }.to raise_error "Illegal state - key expected"
    end

    it 'accepts end_object' do
      expect { subject.end_object }.not_to raise_error
    end

    it 'rejects start_array' do
      expect { subject.start_array }.to raise_error "Illegal state - key expected"
    end

    it 'rejects end_array' do
      expect { subject.end_array }.to raise_error "Illegal state - unexpected array end"
    end

    it 'accepts key' do
      expect { subject.key "test" }.not_to raise_error
    end

    it 'rejects value' do
      expect { subject.value "test" }.to raise_error "Illegal state - key expected"
    end

  end

  context "given started array" do

    before do
      subject.start_document
      subject.start_array
    end

    it 'rejects start_document' do
      expect { subject.start_document }.to raise_error "Illegal state - document already started"
    end

    it 'rejects end_document' do
      expect { subject.end_document }.to raise_error "Illegal state - unexpected end of document"
    end

    it 'accepts start_object' do
      expect { subject.start_object }.not_to raise_error
    end

    it 'rejects end_object' do
      expect { subject.end_object }.to raise_error "Illegal state - unexpected object end, object not started"
    end

    it 'accepts start_array' do
      # a nested array
      expect { subject.start_array }.not_to raise_error
    end

    it 'accepts end_array' do
      # array can be empty
      expect { subject.end_array }.not_to raise_error
    end

    it 'accepts key' do
      expect { subject.key "test" }.to raise_error "Illegal state - unexpected key, must be in object"
    end

    it 'accepts value' do
      expect { subject.value "test" }.not_to raise_error
    end

  end
end

