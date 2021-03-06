describe "SpecificationFile",
{
	"given a SpecificationFile that is passed a file manifest": ->
		manifest =
			name: "test.coffee"
			url: "/specs/test.coffee"
			path: "test.coffee"
		@restorejQuery = mock jQuery, {
			ajax: (options) ->
				options.success ""
		}
		@file = new witness.SpecificationFile manifest

	"when the file is downloaded": async ->
		@file.on.downloading.addHandler => @downloadingEventRaised = true
		@file.on.downloaded.addHandler => @downloadedEventRaised = true; @done()
		@file.download()

	then:
		downloadingEventRaised: should.be true
		downloadedEventRaised: should.be true

	dispose: ->
		@restorejQuery()
},
{
	"given a SpecificationFile with a file manifest of a CoffeeScript file with a syntax error": ->
		manifest =
			name: "test.coffee"
			url: "/specs/test.coffee"
			path: "test.coffee"
		@restorejQuery = mock jQuery, {
			ajax: (options) -> options.success " { "
		}
		@file = new witness.SpecificationFile manifest

	"when the file is downloaded": async ->
		@file.on.downloadFailed.addHandler => @failed = yes; @done()
		@file.download()

	then:
		failed: should.be yes

	dispose: ->
		@restorejQuery()
},
{
	"given a SpecificationFile with a file manifest of a JavaScript file with a syntax error": ->
		manifest =
			name: "test.js"
			url: "/specs/test.js"
			path: "test.coffee"
		@restorejQuery = mock jQuery, {
			ajax: (options) -> options.success " { "
		}
		@file = new witness.SpecificationFile manifest

	"when the file is downloaded": async ->
		@file.on.downloadFailed.addHandler => @failed = yes; @done()
		@file.download()

	then:
		failed: should.be yes

	dispose: ->
		@restorejQuery()
},
{
	"given a SpecificationFile with a file manifest of a JavaScript file with a runtime error": ->
		manifest =
			name: "test.js"
			url: "/specs/test.js"
			path: "test.coffee"
		@restorejQuery = mock jQuery, {
			ajax: (options) -> options.success "should.callFunctionThatDoesNotExist();"
		}
		@file = new witness.SpecificationFile manifest

	"when the file is downloaded": async ->
		@file.on.downloadFailed.addHandler => @failed = yes; @done()
		@file.download()

	then:
		failed: should.be yes

	dispose: ->
		@restorejQuery()
}
