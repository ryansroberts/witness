# reference "_namespace.coffee"
# reference "ActionViewModel.coffee"

{ ActionViewModel } = @Witness.ui

@Witness.ui.ScenarioViewModel = class ScenarioViewModel

	constructor: (@scenario) ->
		@givenDescription = @scenario.given.description
		@givenActions = actionsViewModel @scenario.given.actions
		@whenDescription = @scenario.when.description
		@whenActions = actionsViewModel @scenario.when.actions
		@thenDescription = @scenario.then.description
		@thenActions = actionsViewModel @scenario.then.actions
		@errors = ko.observableArray []

		@scenario.on.failed.addHandler (errors) =>
			if jQuery.isArray errors
				for error in errors when not error.stack
					error.stack = ""
				@errors errors
			else
				if not errors.stack
					errors.stack = ""
				@errors [ errors ]

	templateId: "scenario"

actionsViewModel = (actions) ->
	(new ActionViewModel action for action in actions)