require "./spec_helper"

record Todo, name : String, priority : Int32, expires_at : Time?, created_at : Time?, updated_at : Time?

class TodoRenderer < Crinder::Base(Todo)
  field name : String, as: title
  field priority : Int, filter: ->{ object.priority * 10 }
  field expires_at : String, as: deadline, unless: ->{ object.priority < 3 }
  field created_at : String, if: ->{ object.priority > 5 }
  field updated : Bool, filter: updated?

  def self.updated?
    !object.updated_at.nil?
  end
end

describe Crinder::Base do
  it "converts object to json" do
    time = Time.new(2018, 1, 29, 15, 23, 15)
    t = Todo.new("www", 8, time + 20.hours, time, nil)

    TodoRenderer.render(t).should eq(%({"title":"www","priority":80,"deadline":"2018-01-30 11:23:15","created_at":"2018-01-29 15:23:15","updated":false}))
  end
end
