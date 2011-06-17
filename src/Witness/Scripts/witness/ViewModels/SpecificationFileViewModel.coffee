# reference "../../lib/knockout.js"
# reference "ViewModels.coffee"

this.Witness.ViewModels.SpecificationFileViewModel = class SpecificationFileViewModel

	constructor: (@file) ->
		@name = @file.name
		@status = ko.observable "notdownloaded"
		@isOpen = ko.observable false
		@specifications = ko.observableArray []
		@errors = ko.observableArray []
		@canRun = ko.dependentObservable =>
			result = null
			switch @status()
				when "downloaded", "passed", "failed" then result = yes
				else result = no
			result

		@file.on.downloading.addHandler =>
			@errors.removeAll()
			@specifications.removeAll()
			@status "downloading"
		@file.on.downloaded.addHandler (errors) =>
			if not errors
				@status "downloaded"
				@specifications (new Witness.ViewModels.SpecificationViewModel spec for spec in @file.specifications)
			else
				@status "errors"
				@errors.push error for error in errors

		@file.on.running.addHandler => @status "running"
		@file.on.passed.addHandler => @status "passed"
		@file.on.failed.addHandler => @status "failed"
		
	download: ->
		@file.download()

	run: (done = (->)) ->
		@file.run {}, done, done if @canRun()
		
	reset: ->
		specification.reset() for specification in @specifications()

	toggleOpen: ->
		@isOpen(not @isOpen())

	scenarioTemplate: (item) ->
		if item instanceof Witness.ViewModels.OuterScenarioViewModel
			"outer-scenario"
		else
			"scenario"
