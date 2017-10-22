# Abstract

`json-stream-processor` is a simple tool helping processing huge JSON files without loading entire file into memory.

# History and motivation

I needed to process a large JSON file that was just an array of items similar to:
```
[
  {"username": "test1", "id": 312, "details": {"age": 30, ...}},
  {"username": "test2", "id": 223, "details": {"age": 34, ...}}
]
```
I only needed to extract a couple of properties from each array element but the tool that I would normally use (`jq`) could not deal with the file because of its size.
Also, while each item in the example above is on a separate line suggesting you may use tools like `grep`, `sed`, `awk` etc, the real file had no spaces in it so was one 
long line, hundreds of megabytes is size. (To be fair, `jq` supports `--stream` option but it changes representation of data completely,
so given that and also the fact that ideally I wanted to implement some complex selection logic, I decided to move on)

Some Googling found [json-stream](https://github.com/dgraham/json-stream) and [yajl-ffi](https://github.com/dgraham/yajl-ffi) which provide SAX-like parsing - your
callbacks are invoked as data is being parsed. However that implies you have to reconstruct document yourself from these callbacks.

Finally, [json-streamer](https://github.com/thisismydesign/json-streamer) promised to do exactly what I needed - it has a builder that when plugged into that [json-stream](https://github.com/dgraham/json-stream)-like parser constructs these documents and allow you to only select elements at certain level. This is exactly what I wanted - to only deal with elements at depth 1.

However in test [json-streamer](https://github.com/thisismydesign/json-streamer) still managed to eat all the memory so I decided to write my own.

# Installation

The tool itself does not have any installer, you just need to grab a copy from Github. 
However you need to install one of the SAX-like parsers which you planning to use.
You can use it either [json-stream](https://github.com/dgraham/json-stream) and [yajl-ffi](https://github.com/dgraham/yajl-ffi). I used the latter one as it is much faster.

```
sudo gem install yajl-ffi
```

However, it installs native extension so if you cannot use these, go with the former one

```
sudo gem install json-stream
```

The usage is the same, the only difference is what you require and how you initialise parser:

```ruby
# for yajl-ffi
require 'yajl/ffi'
parser = Yajl::FFI::Parser.new

# for json-stream
require 'json/stream'
parser = JSON::Stream::Parser.new
```

# Basic use

```ruby
require 'yajl/ffi'

require_relative 'lib/array_processor'
require_relative 'lib/get_path'

class ValueProcessor
  def process(value)
    # Do something with your value here
    # For my test JSON values sent here are in this format:
    #   {"username": "test1", "details": {"age": 30, ...}}
    #
    username = get_path(value, ["username"])
    age = get_path(value, ["details", "age"])
    puts "#{username},#{age}"
  end
end

builder = JsonArrayProcessor.new(ValueProcessor.new)

file = File.open('file.json')
parser = Yajl::FFI::Parser.new
builder.attach(parser)

file.each(32768) { |chunk| parser << chunk }

```

`JsonArrayProcessor` is a special kind of builder that invokes processor given in the constructor with each level-1 item read from JSON (array itself being level-0 or root).
The important thing is that item itself is not added to any bigger object by `JsonArrayProcessor` and is discarded from memory as soon as processor returns.
This allows parsing JSON containing million of entries without the need of loading all of them into the memory.

The `get_path` above is just a utility method that allows you to get some value from a depth of JSON object without need to verify existence of each key as you descend.

# Advanced use

The `JsonArrayProcessor` is just a specific implementation but its superclass `StreamBuilder` is a general purpose tool you can use for your needs.
It is a builder that reconstructs the object driven by parser's callback but what makes it different is that it invokes its own overridable method `append`
for each value or object it reads.

The `append` method is invoked for ALL object and values, not just top level ones. When invoked, the method has access to the current position in the JSON (via calls to `level`,
`pos`, `path`), the value just read (which can be a primitive value or an object) and also the current containing object where this value belongs to (via call to `parent`).
Note that `append` is invoked **at the end of the value** - when it is fully read. See the example below showing invocations of `append` method for a sample JSON.

```
  {
    "key1": true,       // level=1, path=["key1"],                pos="key1",  value=true
    "key2": [
      "hello",          // level=2, path=["key2", 0],             pos=0,       value="hello"
      {
        "inner": [
          100           // level=4, path=["key2", 1, "inner", 0], pos=0,       value=100
        ]               // level=3, path=["key2", 1, "inner"],    pos="inner", value=[100]
      }                 // level=2, path=["key2", 1],             pos=1,       value={"inner": [100]}
    ]                   // level=1, path=["key2"],                pos="key2",  value=[]
  }                     // level=0, path=[],                      pos=nil,     value={"key1": true}
```

Note that `append` start receiving deeply nested values first visiting upper levels as the object is being build.

The default action of `append` method is to include value/object just read into the larger object being build. So if you do not override the method, `StreamBuilder`
will just construct you the same object a regular JSON parser would do.

However you can override `append` method and make a decision whenever to include particular value/object or not based on the current path in the document, or a current nesting level.
So you can filter what ends up in the document being build.
When overriding `append`, you need to invoke `super` if you want normal processing to happen and value/object found to be included into higher level object.
When `super` is not invoked, the `append` method can use the value as it wants but the value won't be included into the document beind build. For example

```ruby
  def append(value)
    if level == 1 then
      puts value
    else
      super
    end
  end
```

Will just print every level-1 object but they won't be included into the document so the memory used by them will be released.
This is exactly what `JsonArrayProcessor` does.

Another example how you can use `append` is to filter out some large object that is not needed in the result.
Imagine you want to keep the original JSON from my example in "History and motivation"
but want to drop "details" object from each item because you do not need it and it takes a lot of space.

```ruby
  def append(value)
    super unless level == 2 and key == "details"
  end
```

will drop the "details" object appearing anywhere on the second level.
Note that `append` is called **after** the object has been extracted so in the example above, the details is alredy fully built and received as `value`
parameter. So some resources both memory and CPU were already spent in order to build it. Still by not including it into the resulting object you can be generating
a way smaller file for further processing.

# Performance

You probably are not concerned with performance too much if you are processing your JSON with Ruby but anyways, lets have some numbers.

First of all, choice os the parser

My `test.json` is about 200Mb in size and has an array with about 2M entries.

```ruby
require 'json/stream'
file = File.open('test.json')
parser = JSON::Stream::Parser.new
file.each(32768) { |chunk| parser << chunk }
```

Note that test code does not use anything from `json-stream-processor` yet, it is purely how much time it takes for parser to go through the entire test file.

```
$ time ruby perf-jsonstream.rb

real	2m19.104s
user	2m18.908s
sys	0m0.088s
```
and

```ruby
require 'yajl/ffi'
file = File.open('test.json')
parser = Yajl::FFI::Parser.new
file.each(32768) { |chunk| parser << chunk }
```

```
$ time ruby perf-yajl.rb

real	0m21.244s
user	0m21.020s
sys	0m0.140s
```
Now you see why I prefer that second parser, it is 5 times faster.

Now if we throw `json-stream-processor` into the mix
```ruby
require 'yajl/ffi'
require_relative 'lib/array_processor'
require_relative 'lib/get_path'

class NoopValueProcessor
  def process(value)
    # No op
  end
end

file = File.open('test.json')
parser = Yajl::FFI::Parser.new
builder = JsonArrayProcessor.new(NoopValueProcessor.new)
builder.attach(parser)
file.each(32768) { |chunk| parser << chunk }
```
So we invoke our value processor for each item in the array but it does nothing. By comparing with dry run above we can measure cost of building all the object and the overhead.
```
$ time ruby perf-jsonstreamprocessor.rb 

real	1m30.301s
user	1m30.064s
sys	0m0.092s
```

