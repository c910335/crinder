module Crinder::Option
  macro option(decl, &block)
    {%
      if decl.is_a? TypeDeclaration
        name = decl.var.id
        type = decl.type
        value = decl.value
        OPTIONS[name] = {} of Nil => Nil
        OPTIONS[name][:type] = type
        if !value.is_a? Nop
          OPTIONS[name][:default] = value
        end
      elsif decl.is_a? Assign
        name = decl.target.id
        value = decl.value
        OPTIONS[name] = {} of Nil => Nil
        OPTIONS[name][:default] = value
      else
        OPTIONS[decl.id] = {} of Nil => Nil
      end
    %}
  end
end
