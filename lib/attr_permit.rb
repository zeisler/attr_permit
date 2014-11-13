require 'active_support/core_ext/big_decimal'

class AttrPermit

  class << self

    def permissible_methods
      @permissible_methods ||= []
    end

    def mapped_methods
      @mapped_methods ||= []
    end

    def attr_permit(*permissible_methods)
      self.permissible_methods.concat [*permissible_methods, *get_super_permissible_methods]
      self.permissible_methods.each do |meth|

        send(:define_method, meth) do
          call_method(meth)
        end

        attr_writer meth unless public_instance_methods.include?("#{meth}=")
      end
    end

    def map_attributes(map_hash)
      map_hash.each do |to, from|
        map_attribute to, from
      end
    end

    def map_attribute(to, from)
      self.mapped_methods.concat [*to, *get_super_mapped_methods]
      if from.is_a? Proc
        send(:define_method, to) do
          instance_exec(&from)
        end
      else
        send(:define_method, to) do
          call_method(from)
        end
      end
    end

    protected

    def get_super_permissible_methods
      superclass.permissible_methods unless superclass == AttrPermit
    end

    def get_super_mapped_methods
      superclass.mapped_methods unless superclass == AttrPermit
    end

  end
  protected
  attr_reader :source
  public

  def initialize(source=nil)
    @source = source
    update(source)
  end

  def update(source)
    return if source.nil?
    source = OpenStruct.new(source) if source.class <= Hash
    self.class.permissible_methods.each do |meth|
      send("#{meth}=", source.send(meth)) if source.respond_to? meth
    end
  end

  def call_method(meth)
    callable = instance_variable_get("@#{meth}")
    instance_variable_set("@#{meth}", callable.call) if callable.respond_to?(:call)
    instance_variable_get("@#{meth}")
  end

  protected :call_method

  def map_hash(big_decimal_as_string: false, all_values_as_string: false)
    hasher([*self.class.mapped_methods], big_decimal_as_string, all_values_as_string)
  end

  def permit_hash(big_decimal_as_string: false, all_values_as_string: false)
    hasher([*self.class.permissible_methods], big_decimal_as_string, all_values_as_string)
  end

  def to_hash(big_decimal_as_string: false, all_values_as_string: false)
    hasher([*self.class.permissible_methods, *self.class.mapped_methods], big_decimal_as_string, all_values_as_string)
  end

  alias_method :to_h, :to_hash

  def non_nil_values(hash_type=:to_hash)
    hash = {}
    send(hash_type).each { |k, v| hash[k] = v unless v.nil? }
    hash
  end

  def ==(obj)
    self.hash == obj.hash
  end

  def is_equivalent?(obj)
    self_hash = self.to_hash
    obj_hash = obj.to_hash
    self_hash.each { |k, v| self_hash[k] = v.to_s }
    obj_hash.each { |k, v| obj_hash[k] = v.to_s }
    self_hash == obj_hash
  end

  def hash
    self.to_hash.hash
  end

  def to_enum
    copy = self.dup
    copy.singleton_class.send(:include, Enumerable)

    def copy.each(&block)
      self.class.permissible_methods.each do |item|
        block.call(public_send(item))
      end
    end

    copy
  end

  private

  attr_reader :big_decimal_as_string, :all_values_as_string

  def big_decimal_as_string_convert(object)
    val = if big_decimal_as_string
            object.to_s if object.class <= BigDecimal
          end
    return object if val.nil?
    val
  end

  def all_values_as_string_convert(object)
    val = if all_values_as_string
            object.to_s if object.respond_to?(:to_s)
          end
    return object if val.nil?
    val
  end

  def to_hash_object(object)
    if object.respond_to?(:to_hash) && object.class <= AttrPermit
      value = object.to_hash(big_decimal_as_string: big_decimal_as_string, all_values_as_string: all_values_as_string)
    end
    if object.respond_to?(:to_hash) && !(object.class <= AttrPermit)
      value = object.to_hash
    end
    return object if value.nil?
    value
  end

  def array_to_hash(object)
    if object.class <= Array
      value = object.map do |v|
        to_hash_object(v)
      end
    end
    return object if value.nil?
    value
  end

  def hasher(methods, big_decimal_as_string, all_values_as_string)
    @big_decimal_as_string = big_decimal_as_string
    @all_values_as_string = all_values_as_string
    hash = {}
    methods.each do |var|
      value = send(var)
      value = to_hash_object(value)
      value = big_decimal_as_string_convert(value)
      value = all_values_as_string_convert(value)
      value = array_to_hash(value)
      hash[var] = value
    end
    hash
  end

end

class AttrPermitLazy < AttrPermit

  def self.attr_permit(*permissible_methods)
    self.permissible_methods.concat [*permissible_methods, *get_super_premissible_methods]
    self.permissible_methods.each do |meth|

      send(:define_method, meth) do
        callable = instance_variable_get("@#{meth}")
        instance_variable_set("@#{meth}", callable.call) if callable.respond_to?(:call)
        instance_variable_get("@#{meth}")
      end

      attr_writer meth unless public_instance_methods.include?("#{meth}=")
    end
  end

end

