# reference "_namespace.coffee"
# reference "treeBuilder.coffee"
# reference "ScenarioViewModel.coffee"
# reference "SpecificationViewModel.coffee"
# reference "IframeManager.coffee"
# reference "../witness/TryAll.coffee"
# reference "../witness/Event.coffee"
# reference "../witness/MessageBus.coffee"

{ TryAll, Event, messageBus } = @Witness
{
	treeBuilder,
	ScenarioNode,
	SpecificationNode,
	ScenarioViewModel,
	SpecificationViewModel,
	IframeManager
} = @Witness.ui

@Witness.ui.RunnerViewModel = class RunnerViewModel

	constructor: (manifest) ->
		@rootDirectory = manifest.rootDirectory
		@tree = treeBuilder.buildTree manifest.rootDirectory
		@scenarioViewModels = {} # ID -> view model
		@activeItemModel = ko.observable null
		@activeItem = ko.observableArray []
		@iframeManager = new IframeManager()
		@canRun = ko.observable yes
		@setupInvoked = new Event()
		@status = ko.observable ""
		@showScenarioActions = ko.observable no

		@tree.map (node) =>
			if node instanceof ScenarioNode
				@scenarioViewModels[node.data.uniqueId] = new ScenarioViewModel node.data

		@canRunSelected = ko.dependentObservable =>
			@canRun() and @activeItemModel()?
		@tree.nodeSelected.addHandler (node) =>
			@treeNodeSelected node

	templateId: "runner-screen"

	activeItemTemplateId: (item) ->
		item.templateId
		
	getScenarioViewModel: (scenario) ->
		id = scenario.uniqueId
		@scenarioViewModels[id]

	treeNodeSelected: (node) ->
		@activeItemModel node.data
		if node instanceof ScenarioNode
			@activeItem [ @getScenarioViewModel node.data ]
			@iframeManager.show node.data.uniqueId

		else if node instanceof SpecificationNode
			@activeItem [ new SpecificationViewModel node.data ]
			@iframeManager.hideActive()

		else
			@activeItem.removeAll()
			@iframeManager.hideActive()

	run: (item) ->
		@canRun no
		@status "Running..."
		passedOrFailed = =>
			@canRun yes
			@status ""
			messageBus.send "RunnerFinished"
		item.run {}, passedOrFailed, passedOrFailed

	runAll: ->
		@run @rootDirectory

	runSelected: ->
		@run @activeItemModel()

	reloadSelected: ->
		# TODO: implement reloading of directories and files

	setup: ->
		@setupInvoked.raise()