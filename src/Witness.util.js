﻿Witness.util = (function () {

    return {
        lift: lift,
        liftAssertion: liftAssertion,
        sequence: sequence,
        async: async,
        runFunctionSequence: runFunctionSequence,
        parseFunctionName: parseFunctionName
    };

    function lift(originalFunction) {
        return function () {
            var capturedArguments = arguments;
            var action = function (done, fail) {
                if (!done) throw new Error("Success callback required.");
                if (!fail) throw new Error("Error callback required.");

                if (getMetadata(originalFunction, "async")) {
                    originalFunction.apply({ done: done, fail: fail }, capturedArguments);
                } else {
                    try {
                        originalFunction.apply({}, capturedArguments);
                        done();
                    } catch (e) {
                        fail(e);
                    }
                }
            };
            setMetadata(action, "action", true);
            return action;
        }
    }

    function liftAssertion(assertion) {
        return function () {
            var action = function (resultCallback) {
                if (!resultCallback) throw new Error("resultCallback required.");

                try {
                    var result = assertion();
                    if (typeof result === "undefined") {
                        resultCallback(new Error("Assertion did not return a value."));
                    } else if (result) {
                        resultCallback(true);
                    } else {
                        resultCallback(new Error("assertion failed"));
                    }
                } catch (e) {
                    resultCallback(e);
                }
            }
            setMetadata(action, "action", true);
            return action;
        }
    }

    function sequence(actions) {
        if (!actions.every(function (action) { return getMetadata(action, "action"); }))
            throw new TypeError("Functions must be actions. Make sure you have actually invoked your step functions e.g. `sendMessage()` instead of just `sendMessage`.");

        var action = function (done, fail) {
            // build the sequence of functions.
            // e.g. [a,b,c] -> function() { a(function() { b(function() { c(done, fail) }, fail) }, fail) }
            var go = actions.reduceRight(
                function (acc, action) {
                    return function () { action(acc, fail) };
                },
                done
            );
            go();
        }
        setMetadata(action, "action", true);
        return action;
    }

    function runFunctionSequence(objects, getRunFunction, callback) {
        var go = objects.reduceRight(
                function (callback, obj) {
                    return function () {
                        getRunFunction(obj).call(obj, callback);
                    }
                },
                callback
            );
        go();
    }

    function async(func) {
        if (typeof func !== "function") throw new TypeError("function required.");
        setMetadata(func, "async", true);
        return func;
    }

    function parseFunctionName(func) {
        return func.toString()
                   .match(/function\s+(.*)\s*\(/)[1];
    }

    // store additional metadata in an object added to a function.
    function getMetadata(func, name) {
        if (func.witnessMetadata) return func.witnessMetadata[name];
        return null;
    }

    function setMetadata(func, name, value) {
        func.witnessMetadata = (func.witnessMetadata || {});
        func.witnessMetadata[name] = value;
    }
})();