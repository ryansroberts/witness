﻿/// <reference path="../util.js" />

Witness.dsl.addInitializer(function (target) {

    target.describe = function Witness_describe(specificationName, scenarios) {
        var specification = new Witness.Specification(specificationName, scenarios);
        Witness.theRunner.addSpecification(specification);
        return specification;
    };

    target.given = function Witness_given() {
        if (arguments[arguments.length - 1] instanceof Array) {
            return createParentScenario(arguments);
        }

        var contexts = convertAll(arguments, convertToStep);
        var actions;

        return {
            contexts: contexts,
            when: when, // Declares steps to run.
            then: then  // Can jump directly to assertions if no actions are required.
        };

        function when() {
            actions = convertAll(arguments, convertToStep);
            return {
                then: then // Declares assertions to run.
            };
        }

        function then() {
            var assertions = convertAll(arguments, convertToAssertion);
            return new Witness.Scenario(
                contexts,
                (actions || []),
                assertions
            );
        }

        function convertAll(args, convert) {
            var array = args ? Array.prototype.slice.apply(args) : [];
            return array.map(convert);
        }

        function convertToStep(item) {
            if (item.run) {
                return item; // Already a step
            }

            if (typeof item === "function") {
                var description = Witness.util.parseFunctionName(item);
                return item.async ? new Witness.Steps.AsyncStep(item, [], description) : new Witness.Steps.Step(item, [], description);
            }

            if (typeof item === "string") {
                return Witness.steps.findMatchingStep(item);
            }
        }

        function convertToAssertion(item) {
            if (item.run) {
                return item; // Already a step
            }

            if (typeof item === "function") {
                var description = Witness.util.parseFunctionName(item);
                return item.async ? new Witness.Steps.AsyncAssertion(item, [], description) : new Witness.Steps.Assertion(item, [], description);
            }

            if (typeof item === "string") {
                return Witness.steps.findMatchingStep(item);
            }
        }

        function createParentScenario(originalArguments) {
            originalArguments = [].slice.call(originalArguments);
            var contexts = originalArguments.slice(0, originalArguments.length - 1);
            var children = originalArguments[originalArguments.length - 1];
            return new Witness.ParentScenario(contexts, children);
        }
    };

});