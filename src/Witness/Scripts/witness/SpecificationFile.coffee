# reference "Witness.coffee"
# reference "../lib/knockout.js"
# reference "../lib/coffee-script.js"
# reference "Event.coffee"

Witness = this.Witness

extractRuntimeErrorFromStack = (stack) ->
	firstLine = stack.match(/^(.*)(:?\r|\n|$)/)[1]
	location = stack.match(/sandbox\.htm:(\d+):(\d+)/)
	
	if location? 
		"#{firstLine}. Line #{location[1]}, character #{location[2]}."
	else
		firstLine

Witness.SpecificationFile = class SpecificationFile extends Witness.ScriptFile

	constructor: (manifest, @helpers = []) ->
		super manifest.url
		@name = manifest.name
		@on.ready = new Witness.Event()
		@on.running = new Witness.Event()
		@on.passed = new Witness.Event()
		@on.failed = new Witness.Event()
		@specifications = []

	scriptDownloaded: (script, done, fail) ->
		@executeSpecificationScript script,
			(specs) =>
				@specifications.push spec for spec in specs
				@on.ready.raise()
				done()
			(error) =>
				@errors.push error
				@on.downloadFailed.raise @errors
				fail error

	executeSpecificationScript: (script, gotSpecifications, fail) ->
		iframe = $("<iframe src='sandbox.htm'/>").hide().appendTo("body")
		iframe.load () =>
			iframeWindow = iframe[0].contentWindow
			iframeDoc = iframeWindow.document
			body = iframeDoc.getElementsByTagName("head")[0]
			addScript = (scriptText) ->
				scriptElement = iframeDoc.createElement "script"
				scriptElement.type = "text/javascript"
				scriptElement.async = false # else some browser seem to execute scripts in non-sequential order!
				if document.createElement("script").textContent == ""
					scriptElement.textContent = scriptText
				else
					scriptElement.innerText = scriptText
				body.appendChild scriptElement

			# Add a function to the iframe window that will be called when the script has finished running.
			iframeWindow._witnessScriptCompleted = ->
				gotSpecifications dsl.specifications or []
			failed = false
			iframeWindow._witnessScriptError = (args...) ->
				failed = true
				error = args[0]
				if typeof error.stack == "string"
					message = extractRuntimeErrorFromStack error.stack
					fail.call this, new Error message
				else
					fail.apply this, args

			dsl = new Witness.Dsl iframeWindow
			dsl.activate()

			wrapScript = (script) -> """
			try {
				#{script}
			} catch (e) {
				_witnessScriptError(e);
			}
			"""
			for helper in @helpers
				addScript wrapScript helper.script
				break if failed
			addScript wrapScript script if not failed
			addScript "_witnessScriptCompleted();" if not failed

	run: (context, done, fail) ->
		Witness.messageBus.send "SpecificationFileRunning", this
		@on.running.raise()
		tryAll = new Witness.TryAll @specifications
		tryAll.run context,
			=>
				Witness.messageBus.send "SpecificationFilePassed", this
				@on.passed.raise()
				done()
			(error) =>
				@on.failed.raise(error)
				Witness.messageBus.send "SpecificationFileFailed", this
				fail(error)
