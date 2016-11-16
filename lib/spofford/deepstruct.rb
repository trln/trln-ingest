require 'ostruct'

## allows conversion of hash to an openstruct, recursively; this makes
# access to Argot documents in ERB templates a little nicer, syntactically, but has a performance
# cost.
module DeepStruct
  def to_ostruct_deep
    case self
      when Hash
        root = OpenStruct.new(self)
        self.each_with_object(root) do |(k,v), o|
          o.send("#{k}=", v.to_ostruct_deep)
        end
        root

    when Array
      self.map do |v|
        v.to_ostruct_deep
      end
    else
      self
    end
  end
end

Object.send(:include, DeepStruct)