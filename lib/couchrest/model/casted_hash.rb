#
# Wrapper around Hash so that the casted_by attribute is set.

module CouchRest::Model
  class CastedHash < Hash
    include CouchRest::Model::CastedBy
    include CouchRest::Model::Dirty
    attr_accessor :casted_by_property

    def self.[](hash, property, parent = nil)
      obj = super(hash)
      obj.casted_by_property = property
      obj.casted_by = parent unless parent.nil?
      obj
    end

    # needed for dirty
    def attributes
      self
    end

    def []= key, obj
      couchrest_attribute_will_change!(key) if use_dirty? && obj != self[key]
      super(key, obj)
    end

    def delete(key)
      couchrest_attribute_will_change!(key) if use_dirty? && include?(key)
      super(key)
    end

    def merge!(other_hash)
      if use_dirty? && other_hash && other_hash.kind_of?(Hash)
        will_change(other_hash)
      end
      super(other_hash)
    end

    def replace(other_hash)
      if use_dirty? && other_hash && other_hash.kind_of?(Hash)
        # new keys and changed keys
        will_change(other_hash)
        # old keys
        old_keys = self.keys.reject { |key| other_hash.include?(key) }
        old_keys.each { |key| couchrest_attribute_will_change!(key) }
      end

      super(other_hash)
    end

    def clear
      self.keys.each { |key| couchrest_attribute_will_change!(key) } if use_dirty?
      super
    end

    def delete_if
      if use_dirty? && block_given?
        self.keys.each do |key|
          couchrest_attribute_will_change!(key) if yield key, self[key]
        end
      end
      super
    end

    # ruby 1.9 
    def keep_if
      if use_dirty? && block_given?
        self.keys.each do |key|
          couchrest_attribute_will_change!(key) if !yield key, self[key]
        end
      end
      super
    end

    private
    def will_change(other_hash)
      other_hash.keys.each do |key|
        if self[key] != other_hash[key] || !include?(key)
          couchrest_attribute_will_change!(key)
        end
      end
    end

  end
end
