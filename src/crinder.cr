require "json"
require "./crinder/*"

class Crinder::Base(T)
  class_property! object : T

  macro inherited
    FIELDS = {} of Nil => Nil

    macro finished
      __process
    end
  end

  macro __cast(name)
    {% type = FIELDS[name.id][:type].resolve %}
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
      FIELDS[name] = options || {} of Nil => Nil
      FIELDS[name][:type] = type
      filter = options[:filter]
    %}

    def self.{{name}}
      {% if filter.is_a? ProcLiteral %}
        {{filter}}.call
      {% elsif !filter.is_a? NilLiteral %}
        {{filter}}
      {% else %}
        __cast({{name}})
      {% end %}
    end
  end

  macro __if_show(name)
    {%
      options = FIELDS[name.id]
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
          {% for name, options in FIELDS %}
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
