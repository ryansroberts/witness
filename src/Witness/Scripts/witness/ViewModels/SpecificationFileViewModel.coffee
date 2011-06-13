# reference "../../lib/knockout.js"
# reference "ViewModels.coffee"

this.Witness.ViewModels.SpecificationFileViewModel = class SpecificationFileViewModel

	constructor: (@file) ->
		@name = @file.name
		@status = ko.observable "notdownloaded"
		@isOpen = ko.observable false
		@specifications = ko.observableArray []
		@canRun = ko.dependentObservable =>
			result = null
			switch @status()
				when "downloaded", "passed", "failed" then result = yes
				else result = no
			result

		@file.on.downloading.addHandler => @status "downloading"
		@file.on.downloaded.addHandler =>
			@status "downloaded"
			@specifications @file.specifications
		@file.on.run.addHandler => @status "running"
		@file.on.done.addHandler => @status "passed"
		@file.on.fail.addHandler => @status "failed"
		
	download: ->
		@file.download()

	run: ->
		@file.run {}, (->), (->) if @canRun()
		
	toggleOpen: ->
		@isOpen(not @isOpen())