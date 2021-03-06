# reference "Witness.coffee"
# reference "../lib/knockout.js"
# reference "../lib/coffee-script.js"
# reference "Event.coffee"
# reference "Dsl.coffee"
# reference "TryAll.coffee"
# reference "MessageBus.coffee"
# reference "ScriptFile.coffee"

{ Dsl, Event, TryAll, ScriptFile, messageBus } = @witness

@witness.SpecificationFile = class SpecificationFile extends ScriptFile

	constructor: (manifest, @helpers = []) ->
		super manifest
		{ @name } = manifest
		jQuery.extend @on, Event.define "running", "passed", "failed"
		@specifications = []

	onDownloading: ->
		@specifications = []
		super()

	scriptDownloaded: ->
		@executeSpecificationScript(
			(specs) =>
				for spec in specs
					spec.parentFile = this
					@specifications.push spec
				@on.downloaded.raise()
			(error) =>
				@on.downloadFailed.raise [ error ]
		)

	executeSpecificationScript: (gotSpecifications, fail) ->
		iframe = jQuery("<iframe src='/_witness/sandbox.htm'/>").hide().appendTo("body")
		iframe.load () =>
			iframeWindow = iframe[0].contentWindow
			iframeDoc = iframeWindow.document
			addScript = (script) -> addInlineScript script, iframeDoc
			failed = false
			# Track current helper (if any) so if it throws an exception
			# we can report it's URL. 
			currentHelper = null

			# Add a function to the iframe window that will be called when the script has finished running.
			iframeWindow._witnessScriptCompleted = ->
				gotSpecifications dsl.specifications or []

			# Global error handling function for the iframe window
			iframeWindow._witnessScriptError = (args...) =>
				failed = true
				error = args[0]
				if typeof error.stack == "string"
					if currentHelper?
						message = extractRuntimeErrorFromStack error.stack, currentHelper
					else
						message = extractRuntimeErrorFromStack error.stack, @script
					fail.call this, new Error message
				else
					fail.apply this, args

			dsl = new Dsl iframeWindow
			dsl.activate()
			
			for helper in @helpers
				currentHelper = helper
				addScript helper.getWrappedScript "_witnessScriptError"
				break if failed
			currentHelper = null
			addScript @getWrappedScript "_witnessScriptError" if not failed
			addScript "_witnessScriptCompleted();" if not failed

	run: (context, done, fail) ->
		messageBus.send "SpecificationFileRunning", this
		@on.running.raise()
		tryAll = new TryAll @specifications
		tryAll.run context,
			=>
				messageBus.send "SpecificationFilePassed", this
				@on.passed.raise()
				done()
			(error) =>
				messageBus.send "SpecificationFileFailed", this
				@on.failed.raise(error)
				fail(error)

# Wrapping a script in an anonymous function call prevents it accidently
# leaking into global scope. The try..catch should catch any runtime errors.
# For example, calling a function that does not exist.
# The global function _witnessScriptError is added to the window executing
# the script by SpecificationFile below.
wrapScript = (script, addFunctionWrap) ->
	script = if addFunctionWrap
		"""
		(function() {
		#{script}
		}());
		"""
	else
		script

	"""
	try {
		#{script}
	} catch (e) {
		_witnessScriptError(e);
	}
	"""

# In Chrome, error objects have a stack string property.
# Parse this to get the error message and also the line and character
# of the error. This makes for a more useful error message to display.
extractRuntimeErrorFromStack = (stack, file) ->
	firstLine = stack.match(/^(.*)(:?\r|\n|$)/)[1]
	location = stack.match(/sandbox\.htm:(\d+):(\d+)/)
	
	if location? 
		line = parseInt(location[1], 10)
		# In JS, line number was offset by 2 in the wrapScript function
		line -= 2 if file.type == "js"
		"#{firstLine}. #{file.path} at line #{line}, character #{location[2]}."
	else
		firstLine

addInlineScript = (scriptText, iframeDoc) ->
	scriptElement = iframeDoc.createElement "script"
	scriptElement.type = "text/javascript"
	scriptElement.async = false # else some browser seem to execute scripts in non-sequential order!
	
	if iframeDoc.createElement("script").textContent == ""
		scriptElement.textContent = scriptText
	else
		scriptElement.innerText = scriptText

	head = iframeDoc.getElementsByTagName("head")[0]
	head.appendChild scriptElement


