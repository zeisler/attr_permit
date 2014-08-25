require 'rspec'
require 'virtus'
require 'active_support/hash_with_indifferent_access'
require_relative '../lib/attr_permit'

RSpec.describe AttrPermit, unit: true do

  before do
    class TestStruct2 < AttrPermit
      attr_permit :baz, :bar
    end

    class TestStruct < AttrPermit
      attr_permit :foo, :bar

    end
  end

  describe '#to_hash' do

    it 'will recursively convert all nested objects into hashs' do
      expect(TestStruct.new(bar: TestStruct.new(bar: 1)).to_hash).to eq({:foo => nil, :bar => {:foo => nil, :bar => 1}})
      expect(TestStruct.new(bar: [TestStruct.new(bar: 1)]).to_hash).to eq({:foo => nil, :bar => [{:foo => nil, :bar => 1}]})
    end

  end

  describe '#call_method' do

    it 'is a protected method that will call a proc or return a value' do
      class CallMethodExample < AttrPermit
        attr_permit :foo

        def _foo
          call_method(:foo)
        end

      end
      expect(CallMethodExample.new(foo: -> { 1 })._foo).to eq 1
      expect(CallMethodExample.new(foo: 1)._foo).to eq 1
    end

  end

  it 'can be initialized with an object with correctly named attribute readers' do
    src = OpenStruct.new(foo: 'hello', bar: nil)
    dest = TestStruct.new(src.to_h)
    hash = dest.to_hash
    expect(hash).to eq({:foo => "hello", :bar => nil})
    expect(dest.foo).to eq('hello')
    expect(hash[:foo]).to eq('hello')
  end

  it 'can be initialized with a hash with correctly named keys' do
    src = {foo: 'hello'}
    dest = TestStruct.new(src)
    hash = dest.to_hash
    expect(dest.foo).to eq('hello')
    expect(hash[:foo]).to eq('hello')
  end

  it 'can be initialized with a HashWithIndifferentAccess with correctly named keys' do
    src = HashWithIndifferentAccess.new({foo: 'hello'})
    dest = TestStruct.new(src)
    hash = dest.to_hash
    expect(dest.foo).to eq('hello')
    expect(hash[:foo]).to eq('hello')
  end

  it 'options big_decimal_as_string: true' do
    obj = TestStruct.new(foo: BigDecimal.new('1.21'))
    expect(obj.to_hash(big_decimal_as_string: true)).to eq({:foo => "1.21", :bar => nil})
  end

  it 'will convert object inside of arrays into hashes' do
    obj = TestStruct.new(foo: [TestStruct.new(bar: BigDecimal.new('1.21'))])
    expect(obj.to_hash(big_decimal_as_string: true)).to eq({:foo => [{:foo => nil, :bar => "1.21"}], :bar => nil})
  end

  context 'to_hash(all_values_as_string: true)' do

    it 'options all_values_as_string: true' do
      obj = TestStruct.new(foo: BigDecimal.new('1.21'))
      expect(obj.to_hash(all_values_as_string: true)).to eq({:foo => "1.21", :bar => ''})
    end

  end

  describe '#non_nil_values' do

    it 'will only return initialized values' do
      struct = TestStruct.new(foo: true)
      expect(struct.non_nil_values).to eq({foo: true})
    end

  end

  describe 'sub classing' do

    before do
      class APermit < AttrPermit
        attr_permit :foo
      end

      class BPermit < APermit
        attr_permit :bar
      end

      class CPermit < BPermit
        attr_permit :baz
      end
    end

    it 'class B will have attributes from A and its own' do
      expect(BPermit.permissible_methods).to eq [:bar, :foo]
      expect(BPermit.instance_methods).to include *[:bar, :bar=, :foo, :foo=]
    end

    it 'class C will have attributes from A, B and its own' do
      expect(CPermit.permissible_methods).to eq [:baz, :bar, :foo]
      expect(CPermit.instance_methods).to include(:baz, :baz=, :bar, :bar=, :foo, :foo=)
    end

    after do
      %w[APermit BPermit CPermit].each { |klass| Object.send(:remove_const, klass) }
    end

  end

  describe 'include Virtus.model' do

    class TestStructVirtus < AttrPermit
      include Virtus.model
      attribute :foo, Boolean
      attribute :bar, BigDecimal
    end

    it 'can be initialized with a hash with correctly named keys' do
      src = {foo: 'true'}
      dest = TestStructVirtus.new(src)
      hash = dest.to_hash
      expect(hash).to eq({:foo => true, :bar => nil})
      expect(dest.foo).to eq(true)
      expect(hash[:foo]).to eq(true)
    end

    it 'can be initialized with a HashWithIndifferentAccess with correctly named keys' do
      src = HashWithIndifferentAccess.new({bar: '123'})
      dest = TestStructVirtus.new(src)
      hash = dest.to_hash
      expect(dest.bar).to eq(123)
      expect(hash[:bar]).to eq(123)
    end

    describe '#non_nil_values' do

      it 'will only return initialized values' do
        struct = TestStructVirtus.new(foo: 'true')
        expect(struct.non_nil_values).to eq({foo: true})
      end

    end

  end

  describe 'lazy load' do

    before do

      class Lazy < AttrPermit
        attr_permit :name
      end

    end

    it 'once called it will memoized' do
      value = 0
      proc = -> { value += 1 }
      lazy = Lazy.new(name: proc)
      lazy.name
      expect(lazy.name).to eq 1
    end

    it 'will lazy load name' do
      lazy = Lazy.new(name: -> { raise('Name was called') })
      expect { lazy.name }.to raise_error('Name was called')
    end

    it 'will call block on to_hash' do
      lazy = Lazy.new(name: -> { raise('Name was called') })
      expect { lazy.to_hash }.to raise_error('Name was called')
    end

  end

end
