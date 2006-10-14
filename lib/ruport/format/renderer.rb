module Ruport

  class Format::Renderer
    
    def self.for(obj)
      r = self.new(obj)
      yield(r); r
    end

    def initialize(obj)
      @renderable_object = obj
      @properties = {}
      @actions    = []
      @defined_actions = {}
    end

    def actions(*verbs)
      return @actions if verbs.empty?
      @actions = verbs
    end

    def actions=(ary)
      actions(*ary)
    end

    def property(name,val)
      @properties[name] = val
    end

    def define_action(name,&block)
      @defined_actions[name] = block
    end
    
    def render
      o = @renderable_object.dup
      @properties.each { |k,v| o.send("#{k}=",v) }

      @actions.map { |a| (b=@defined_actions[a]) ? b[o] : o.send(a) }.last
    end

    def insert_action(name,option={})
      if option[:at].eql? :beginning
        @actions.unshift(name)
      elsif option[:at].eql? :end
        @actions.push(name)
      elsif option[:at].kind_of? Fixnum
        @actions.insert option[:at], name
      elsif option[:after]
        @actions.insert @actions.index(option[:after]) + 1, name
      elsif option[:before]
        @actions.insert @actions.index(option[:before]), name
      end
    end

    def alias_action(new,old)
      if @defined_actions.keys.include? old
          @defined_actions[new] = @defined_actions[old]
      elsif @renderable_object.respond_to? old
        @defined_actions[new] = lambda { |o| o.send old }
      end
    end

  end

end
