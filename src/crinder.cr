require "json"
require "./crinder/*"

# `Crinder::Base` is the base renderer of type T.
#
# To define your own renderer, you need to inherit `Crinder::Base` with specific type and declare the fields with `field`.
#
# For example, this is a renderer of Time.
#
# ```
# class TimeRenderer < Crinder::Base(Time)
#   field year : Int
#   field month : Int
#   field day : Int
#   field hour : Int
#   field minute : Int
#   field second : Int
# end
# ```
#
# Then `.render` will be auto generated.
#
# ```
# time = Time.new(2018, 3, 15, 16, 21, 1)
# TimeRenderer.render(time) # => "{\"year\":2018,\"month\":3,\"day\":15,\"hour\":16,\"minute\":21,\"second\":1}"
# ```
class Crinder::Base(T)
  class_property! object : T

  SETTINGS = {} of Nil => Nil

  # :nodoc:
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

  # Defines a field.
  macro field(decl, **options)
    {%
      name = decl
      type = Nil
      if decl.is_a? TypeDeclaration
        type = decl.type.resolve
        name = decl.var
      end
      name = name.id
      SETTINGS[@type.id][name] = options || {} of Nil => Nil
      SETTINGS[@type.id][name][:type] = type
      value = options[:value]
      render_with = options[:with]
    %}

    {% if value.is_a? NilLiteral %}
      {% SETTINGS[@type.id][name][:value] = name %}

      def self.{{name}}
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
    {% end %}
  end

  # Undefines a field.
  macro remove(name)
    {% name = name.id %}
    {% SETTINGS[@type.id][name] = {:unless => true} %}

    def self.{{name}}
      nil
    end
  end

  # :nodoc:
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

  # :nodoc:
  macro __value_of(name)
    {% value = SETTINGS[@type.id][name.id][:value] %}
    {% if value.is_a? ProcLiteral %}
      {{value}}.call
    {% else %}
      {{value}}
    {% end %}
  end

  # :nodoc:
  macro __process
    def self.render(objects : Array(T)) : String
      JSON.build do |json|
        json.array do
          objects.each do |object|
            render_object(json, object)
          end
        end
      end
    end

    def self.render(object : T) : String
      JSON.build do |json|
        render_object(json, object)
      end
    end

    def self.render_object(json : ::JSON::Builder, object : T) : IO | Nil
      {% if T >= Nil %}
        if object.nil?
          return json.null
        end
      {% end %}
      @@object = object
      json.object do
        {% for name, options in SETTINGS[@type.id] %}
          __if_show({{name}}) do
            %field = "{{(options[:as] || name).id}}"
            {% if render_with = options[:with] %}
              json.field %field do
                {{render_with}}.render_object(json, __value_of({{name}}))
              end
            {% else %}
              json.field %field, __value_of({{name}})
            {% end %}
          end
        {% end %}
      end
    end
  end
end
