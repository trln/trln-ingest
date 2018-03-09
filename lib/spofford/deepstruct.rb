require 'ostruct'

## allows conversion of hash to an openstruct, recursively; this makes
# access to Argot documents in ERB templates a little nicer, syntactically,
# but has a performance cost.
module DeepStruct
  def to_ostruct_deep
    case self
    when Hash
      root = OpenStruct.new(self)
      each_with_object(root) { |(k, v), o| o.send("#{k}=", v.to_ostruct_deep) }
      root
    when Array
      map(&:to_ostruct_deep)
    else
      self
    end
  end
end

Object.send(:include, DeepStruct)
