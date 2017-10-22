
# A helper to allow quickly getting a value at a certain path in JSON object
# without need to verify existence of each element along the path.
#
def get_path(value, *path)
  # Allow calling us as get_path(object, [1, 2, 3])
  # in addition to get_path(object, 1, 2, 3)
  #
  path = path[0] if path.size == 1 and path[0].is_a?(Array)

  while !value.nil? and !path.empty? do
    i = path.shift
    case value
      when Hash
        value = value[i]
      when Array
        value = i.is_a?(Numeric) ? value[i] : nil
      else
        value = nil
    end
  end

  value
end

