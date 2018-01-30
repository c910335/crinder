require "json"
require "./crinder/*"

class Crinder::Base(T)
  class_property! object : T

  SETTINGS = {} of Nil => Nil

  macro __inherited
    {% SETTINGS[@type.id] = {} of Nil => Nil %}
    {% for key, value in SETTINGS[@type.superclass.id] %}
      {% SETTINGS[@type.id][key] = value %}
    {% end %}

    macro inherited
      __inherited
    end

    macro finished
      __process
    end
  end

  macro inherited
    {% SETTINGS[@type.id] = {} of Nil => Nil %}

    macro inherited
      __inherited
    end

    macro finished
      __process
    end
  end

  macro __cast(name)
    {% type = SETTINGS[@type.id][name.id][:type].resolve %}
    {% if type <= Array %}
      object.{{name}}.to_a
    {% elsif type <= Bool %}
      !!object.{{name}}
    {% elsif type <= Float %}
      object.{{name}}.to_f64
    {% elsif type <= Hash %}
      object.{{name}}.to_h
    {% elsif type <= String %}
      object.{{name}}.to_s
    {% elsif type <= Int %}
      object.{{name}}.to_i64
    {% else %}
      object.{{name}}
    {% end %}
  end

  macro field(decl, **options)
    {%
      name = decl.var.id
      type = decl.type
      SETTINGS[@type.id][name] = options || {} of Nil => Nil
      SETTINGS[@type.id][name][:type] = type
      value = options[:value]
    %}

    def self.{{name}}
      {% if value.is_a? ProcLiteral %}
        {{value}}.call
      {% elsif !value.is_a? NilLiteral %}
        {{value}}
      {% else %}
        __cast({{name}})
      {% end %}
    end
  end

  macro remove(name)
    {% name = name.id %}
    {% SETTINGS[@type.id][name] = {:unless => true} %}

    def self.{{name}}
      nil
    end
  end

  macro __if_show(name)
    {%
      options = SETTINGS[@type.id][name.id]
      show_unless = options[:unless]
      show_if = options[:if]
      show_if = true if show_if.is_a? NilLiteral
    %}

    %show = {% if show_unless.is_a? ProcLiteral %}
              !{{show_unless}}.call
            {% else %}
              !{{show_unless}}
            {% end %}
    %show &&= {% if show_if.is_a? ProcLiteral %}
                {{show_if}}.call
              {% else %}
                {{show_if}}
              {% end %}

    if %show
      {{yield}}
    end
  end

  macro __process
    def self.render(object : T) : String
      @@object = object
      JSON.build do |json|
        json.object do
          {% for name, options in SETTINGS[@type.id] %}
            __if_show({{name}}) do
              %field = "{{(options[:as] || name).id}}"
              json.field %field, {{name}}
            end
          {% end %}
        end
      end
    end
  end
end
