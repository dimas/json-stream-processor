require_relative 'stream_builder'

class JsonArrayProcessor < StreamBuilder

  def initialize(processor)
    @processor = processor
  end

  def append(value)
    if level == 1 then
      @processor.process(value)
    else
      super
    end
  end

end

