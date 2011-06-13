﻿# reference "../witness/dsl/describe.coffee"
# reference "../witness/AsyncAction.coffee"

describe "AsyncAction",
{
	"given an AsyncAction where the function throws before going async": ->
		functionThatThrowsBeforeAsync = -> throw new Error "failed"
		@action = new Witness.AsyncAction functionThatThrowsBeforeAsync, []

	"when the action is run": async ->
		testDone = @done
		@action.run {}, (=> @doneCalled = true; testDone()), ((error) => @error = error; testDone())

	then:
		doneCalled: should.be undefined
		error: message: should.be "failed"
},
{
	"given an AsyncAction where the function does nothing and timeout is 10 milliseconds": ->
		functionThatDoesNothing = (->)
		timeToWait = 10 # milliseconds
		@action = new Witness.AsyncAction functionThatDoesNothing, [], null, timeToWait

	"when the action is run": async ->
		testDone = @done
		@action.run {}, (=> @doneCalled = true; testDone()), ((error) => @error = error; testDone())

	then:
		doneCalled: should.be undefined
		error: should.beInstanceof Witness.TimeoutError
},
{
	"given an AsyncAction where the function calls done after a 100 millisecond delay": ->
		functionThatCallsDone = -> setTimeout (=> this.done()), 100
		@action = new Witness.AsyncAction functionThatCallsDone

	"when the action is run": async ->
		testDone = @done
		@action.run {}, (=> @doneCalled = true; testDone()), (=> @failCalled = true; testDone())

	then:
		doneCalled: should.be true
		failCalled: should.be undefined
},
{
	"given an AsyncAction where the function calls fail": ->
		functionThatCallsFail = -> setTimeout (=> this.fail "failed"), 10
		@action = new Witness.AsyncAction functionThatCallsFail

	"when the action is run": async ->
		testDone = @done
		@action.run {}, (=> @doneCalled = true; testDone()), ((error) => @error = error; testDone())

	then:
		doneCalled: should.be undefined
		error: should.be "failed"
}
