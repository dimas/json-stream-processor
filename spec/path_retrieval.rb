require 'get_path'

describe "#get_path" do

  it 'returns nil for any path when object is nil' do
    object = nil
    expect(get_path(object, "key")).to be_nil
    expect(get_path(object, 0)).to be_nil
    expect(get_path(object, "test", "test")).to be_nil
  end

  it 'returns nil for any index in an empty array' do
    object = []
    expect(get_path(object, 0)).to be_nil
    expect(get_path(object, 1)).to be_nil
    expect(get_path(object, 1, 2)).to be_nil
    expect(get_path(object, "test")).to be_nil
  end

  it 'returns values for valid index in an array' do
    object = [100, 200]
    expect(get_path(object, 0)).to eq(100)
    expect(get_path(object, 1)).to eq(200)
    expect(get_path(object, 2)).to be_nil
    expect(get_path(object, "test")).to be_nil
  end

  it 'returns nil for any key in an empty object' do
    object = {}
    expect(get_path(object, "test")).to be_nil
    expect(get_path(object, "key")).to be_nil
    expect(get_path(object, "key", "inner")).to be_nil
    expect(get_path(object, 0)).to be_nil
  end

  it 'returns values for valid keys in an object' do
    object = {"key1" => true, "key2" => 100, "key3" => {"inner" => 200}}
    expect(get_path(object, "key1")).to eq(true)
    expect(get_path(object, "key2")).to eq(100)
    expect(get_path(object, "key3")).to eq({"inner" => 200})
    expect(get_path(object, "key0")).to be_nil
  end

  it 'handles a complex case' do
    object = {
      "k1" => [100, 200],
      "k2" => true,
      "k3" => {
        "k3-1" => "hello",
        "k3-2" => {
        },
        "k3-3" => [
        ],
        "k3-4" => [
          111, true, {"inner" => false}, 222
        ]
      }
    }

    expect(get_path(object, "k1")).to eq([100, 200])
    expect(get_path(object, "k1", 1)).to eq(200)
    expect(get_path(object, "k2")).to eq(true)
    expect(get_path(object, "k3", "k3-1")).to eq("hello")
    expect(get_path(object, "k3", "k3-2")).to eq({})
    expect(get_path(object, "k3", "k3-2", "kx")).to be_nil
    expect(get_path(object, "k3", "k3-4", 1)).to eq(true)
    expect(get_path(object, "k3", "k3-4", 2, "inner")).to eq(false)
  end

end

