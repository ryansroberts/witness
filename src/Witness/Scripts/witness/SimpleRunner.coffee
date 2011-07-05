﻿# reference "Witness.coffee"
# reference "../lib/coffee-script.js"
# reference "../lib/jquery.js"
# reference "../lib/knockout.js"
# reference "MessageBus.coffee"
# reference "Dsl.coffee"
# reference "SpecificationFile.coffee"
# reference "SpecificationDirectory.coffee"
# reference "ViewModels/SpecificationFileViewModel.coffee"
# reference "ViewModels/SpecificationDirectoryViewModel.coffee"

{ SpecificationFile, SpecificationDirectory, Dsl, messageBus } = @Witness
{ SpecificationFileViewModel, SpecificationDirectoryViewModel } = @Witness.ViewModels

@Witness.SimpleRunner = class SimpleRunner
	constructor: (@specsPath, iframeContainer, @autoRun = no) ->
		# Use an observable array, since knockout dislikes binding to a null object.
		# Once loaded, the array will contain the single directory object.
		@directory = ko.observableArray []
		@canRun = ko.observable false
		@status = ko.observable ""
		Witness.messageBus.addHandler "AppendIframe", (iframe) -> iframeContainer.append iframe

	fileSystemItemTemplate: (item) ->
		if item instanceof SpecificationDirectoryViewModel
			"directory"
		else
			"file-of-many"

	download: ->
		@status "Downloading specification manifest..."
		downloadManifest = @downloadSpecificationManifest()
		downloadManifest.done (manifest) =>
			@status "Downloading specifications..."
			isFile = manifest.url?
			{model, viewModel} = @createModelAndViewModelForManifest manifest
			@directory.push viewModel
			viewModel.isOpen true
			model.on.passed.addHandler =>
				@status "Passed"
				@canRun true
				Witness.messageBus.send "RunnerFinished"
			model.on.failed.addHandler =>
				@status "Failed"
				@canRun true
				Witness.messageBus.send "RunnerFinished"

			model.download(
				(=>
					@canRun true
					@status "Ready to run"
					@runAll() if @autoRun
				)
				(=>
					console.log "download error"
					@status "Download error."
					Witness.messageBus.send "RunnerDownloadFailed"
				)
			)

		downloadManifest.fail =>
			@status "Could not download manifest from #{@specsPath}"

	createModelAndViewModelForManifest: (manifest) ->
		Witness.urlBase = manifest.urlBase
		if manifest.file?
			@createSpecificationFileFromManifest manifest.file
		else
			@createSpecificationDirectoryFromManifest manifest.directory

	downloadSpecificationManifest: ->
		$.ajax
			url: "manifest"
			data: { path: @specsPath }
			cache: false

	createSpecificationFileFromManifest: (manifest) ->
		file = new SpecificationFile manifest
		{ model: file, viewModel: new SpecificationFileViewModel file }

	createSpecificationDirectoryFromManifest: (manifest) ->
		dir = new SpecificationDirectory manifest
		{ model: dir, viewModel: new SpecificationDirectoryViewModel dir }

	downloadSpecification: (url) ->
		waitForSpecifications = $.Deferred()
		$.ajax
			url: url
			cache: false
			dataType: "text"
			success: (script) =>
				if url.match(/.coffee$/)
					script = CoffeeScript.compile(script)
				@executeSpecificationScript script, (specs) =>
					@specifications = @specifications.concat specs
					waitForSpecifications.resolve()
		waitForSpecifications

	executeSpecificationScript: (script, gotSpecifications) ->
		iframe = $("<iframe src='/empty.htm'/>").hide().appendTo("body")
		iframe.load () =>
			iframeWindow = iframe[0].contentWindow
			iframeDoc = iframeWindow.document
			
			# Copy all our scripts into the iframe.
			$("head > script[src]").each(() ->
				iframeDoc.write "<script type='text/javascript' src='#{this.src}'></script>"
			)
			
			# Add a function to the iframe window that will be called when the script has finished running.
			iframeWindow._witnessScriptCompleted = ->
				gotSpecifications dsl.specifications

			dsl = new Dsl iframeWindow
			dsl.activate()
			iframeDoc.write "<script type='text/javascript'>#{script}</script>"
			iframeDoc.write "<script type='text/javascript'>_witnessScriptCompleted()</script>"
			

	runAll: () ->
		return if not @canRun()
		@canRun false
		@status "Running..."
		@directory()[0].run()
	
