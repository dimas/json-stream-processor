class StreamBuilder

  # The append(value) method is called at the end of each element read from JSON.
  # Its default action is to include the value just read into the parent (higher level) object.
  # Subclasses can modify this behaviour to prevent some values from being included into
  # document being build and possibly sending them for some other processing.
  #
  # These subclasses can make their decision based on data available from the following methods:
  #   * level() - depth of the value (0 means root)
  #   * path() - which gives path to the value
  #   * pos() - last element of the path - position of the value in its immediate parent.
  #               + nil for root value
  #               + Numeric if parent is a list (Array)
  #               + String if parent is an object (Hash)
  #
  def append(value)
    case parent
      when Hash
        parent[pos] = value
      when Array
        # Technically, pos() is valid for arrays too - it is a numeric position in the array.
        # However if a subclass decides to not pass some values here, the pos, while still valid
        # position in the original JSON may not be a valid position in the array being build. So just append
        parent << value
      when nil
        # Root
        set_root value
      else
        state_error "unexpected parent: #{parent}"
    end
  end

  # Attach builder to a parser
  #
  def attach(parser)
    %w[start_document end_document start_object end_object start_array end_array key value].each do |name|
      parser.send(name, &method(name))
    end
  end

  # Callbacks for JSON::Stream::Parser / Yajl::FFI::Parser

  def start_document
    check @stack.nil?, "document already started"

    @stack = []
    @root_set = false
    @root = nil
  end

  def end_document
    check_started
    check @stack.empty?, "unexpected end of document"

    @stack = nil
  end

  def start_object
    check_started
    check_value_allowed

    @stack << {:object => {}, :key => nil}
  end

  def end_object
    check_started
    check parent.is_a?(Hash), "unexpected object end, object not started"
    check pos.nil?, "unexpected object end, a value expected"

    append @stack.pop[:object]
    advance
  end

  def start_array
    check_started
    check_value_allowed

    @stack << {:object => [], :pos => 0}
  end

  def end_array
    check_started
    check parent.is_a?(Array), "unexpected array end"

    append @stack.pop[:object]
    advance
  end

  def key(k)
    check_started
    check parent.is_a?(Hash), "unexpected key, must be in object"
    check pos.nil?, "unexpected key, already set"

    @stack[-1][:pos] = k
  end

  def value(v)
    check_started
    check_value_allowed

    append v
    advance
  end

  # End of callbacks

  # Gets the object built
  def result
    @root
  end

  private

  def state_error(text)
    raise "Illegal state - #{text}"
  end

  def check(condition, message)
    state_error message unless condition
  end

  def check_started
    check !@stack.nil?, "document not started"
  end

  def check_value_allowed
    check !parent.is_a?(Hash) || !pos.nil?, "key expected"
  end

  def set_root(value)
    check !@root_set, "root is already read"
    @root = value
    @root_set = true
  end

  # This is called after append() to indicate we finished processing a value
  # It increment current item position if we are in an array
  # or resets the current key if we are in an object
  def advance()
    return if @stack.empty?
    top = @stack[-1]
    case parent
      when Hash
        top[:pos] = nil
      when Array
        top[:pos] += 1
    end
  end

  # The key into which the value in append() is to be placed into parent. Can be
  #   * nil - if the value is root of the document
  #   * Numeric - position in the array if parent is Array (list)
  #   * String - key in the Hash if parent is Hash (object)
  #
  def pos
    @stack.empty? ? nil : @stack[-1][:pos]
  end

  # Parent container into which value in append() needs to be placed. Can be
  #   * nil - if the value is root of the document
  #   * Array - when value is an item in a list
  #   * Hash - when value is a field in an object
  #
  def parent
    @stack.empty? ? nil : @stack[-1][:object]
  end

  # level or depth of the value in append(). Zero means the value is the root one
  #
  def level
    @stack.size
  end

  # Gives path to the value sent into append() method.
  # Path is empty for a value at the top of the document root.
  # Otherwise path is an Array of where each element is either a String
  # which is a key in an object or a Number being position in a list
  #
  # For example, in this JSON
  #
  #   { "key1": [10, 20, {"abc": "xyz"}, 30] }
  #
  # The value "xyz" hash path ["key1", 2, "abc"]
  #
  def path
    @stack.collect{|i| i[:pos]}
  end

end

