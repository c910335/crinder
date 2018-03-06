# crinder

Class based json renderer in Crystal

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crinder:
    github: c910335/crinder
```

## Usage

### Basic

```crystal
require "crinder"

record Todo, name : String, priority : Int32, expires_at : Time?, created_at : Time?, updated_at : Time?

class TodoRenderer < Crinder::Base(Todo)
  field name : String, as: title
  field priority : Int, value: ->{ object.priority * 10 }
  field expires_at : String, as: deadline, unless: ->{ object.priority < 3 }
  field created_at : String, if: ->{ object.priority > 5 }
  field updated : Bool, value: updated?

  def self.updated?
    !object.updated_at.nil?
  end
end

time = Time.new(2018, 1, 29, 15, 23, 15)
todo = Todo.new("www", 8, time + 20.hours, time, nil)

TodoRenderer.render(todo) # => "{\"title\":\"www\",\"priority\":80,\"deadline\":\"2018-01-30 11:23:15\",\"created_at\":\"2018-01-29 15:23:15\",\"updated\":false}"
```

### Inheritance

```crystal
class AnotherTodoRenderer < TodoRenderer
  remove updated
  remove expires_at
  field updated_at : String
end

todo = Todo.new("wow", 6, time + 20.hours, time, time + 10.hours)

AnotherTodoRenderer.render(todo) # => "{\"title\":\"wow\",\"priority\":60,\"created_at\":\"2018-01-29 15:23:15\",\"updated_at\":\"2018-01-30 01:23:15\"}"
```

### Array

```crystal
todos = [Todo.new("www", 8, time + 20.hours, time, nil), Todo.new("api", 10, time + 21.hours, time, nil)]
TodoRenderer.render(todos) # => "[{\"title\":\"www\",\"priority\":80,\"deadline\":\"2018-01-30 11:23:15\",\"created_at\":\"2018-01-29 15:23:15\",\"updated\":false},{\"title\":\"api\",\"priority\":100,\"deadline\":\"2018-01-30 12:23:15\",\"created_at\":\"2018-01-29 15:23:15\",\"updated\":false}]"
```

## Contributing

1. Fork it ( https://github.com/c910335/crinder/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [c910335](https://github.com/c910335) Tatsiujin Chin - creator, maintainer
