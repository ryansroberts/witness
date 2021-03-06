describe "Event",
{
	"given an Event with a handler added": ->
		@event = new witness.Event()
		@event.addHandler ((args...) => @handlerCalled = true; @args = args)
	
	"for each": [
		{
			"when it is raised": ->
				@event.raise()

			then:
				handlerCalled: should.be true
		},
		{
			"when it is raised with an argument": ->
				@event.raise "arg"

			then:
				args: should.arrayEqual [ "arg" ]
		}
	]
},
{
	"when Event.define is called with event names": ->
		@events = witness.Event.define.call null, "started", "finished"
	
	"then Event objects are created":
		events:
			started: should.beInstanceof witness.Event
			finished: should.beInstanceof witness.Event
}
