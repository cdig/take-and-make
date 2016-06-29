"use strict";
var DebugTakeMake, Make, Take;

if (!((typeof Take !== "undefined" && Take !== null) || (typeof Make !== "undefined" && Make !== null))) {
  Take = null;
  Make = null;
  DebugTakeMake = null;
  (function() {
    var addListener, allNeedsAreMet, alreadyChecking, alreadyWaitingToNotify, asynchronousResolve, checkWaitingTakers, clone, made, notify, notifyTakers, register, resolve, synchronousResolve, takersToNotify, timeoutCount, waitingTakers;
    made = {};
    waitingTakers = [];
    takersToNotify = [];
    alreadyWaitingToNotify = false;
    alreadyChecking = false;
    timeoutCount = 0;
    clone = function(o) {
      if (Object.assign != null) {
        return Object.assign({}, o);
      } else {
        return o;
      }
    };
    Make = function(name, value) {
      if (value == null) {
        value = name;
      }
      if (name == null) {
        return clone(made);
      }
      return register(name, value);
    };
    Take = function(needs, callback) {
      if (needs == null) {
        return waitingTakers.slice();
      }
      return resolve(needs, callback);
    };
    DebugTakeMake = function() {
      var base, i, j, len, len1, need, output, ref, waiting;
      output = {
        timeoutCount: timeoutCount,
        unresolved: {}
      };
      for (i = 0, len = waitingTakers.length; i < len; i++) {
        waiting = waitingTakers[i];
        ref = waiting.needs;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          need = ref[j];
          if (made[need] == null) {
            if ((base = output.unresolved)[need] == null) {
              base[need] = 0;
            }
            output.unresolved[need]++;
          }
        }
      }
      return output;
    };
    register = function(name, value) {
      if (name === "") {
        throw new Error("You may not Make(\"\") an empty string.");
      }
      if (made[name] != null) {
        throw new Error("You may not Make() the same name twice: " + name);
      }
      made[name] = value;
      checkWaitingTakers();
      return value;
    };
    checkWaitingTakers = function() {
      var i, index, len, taker;
      if (alreadyChecking) {
        return;
      }
      alreadyChecking = true;
      for (index = i = 0, len = waitingTakers.length; i < len; index = ++i) {
        taker = waitingTakers[index];
        if (allNeedsAreMet(taker.needs)) {
          waitingTakers.splice(index, 1);
          notify(taker);
          alreadyChecking = false;
          return checkWaitingTakers();
        }
      }
      return alreadyChecking = false;
    };
    allNeedsAreMet = function(needs) {
      return needs.every(function(name) {
        return made[name] != null;
      });
    };
    resolve = function(needs, callback) {
      if (callback != null) {
        asynchronousResolve(needs, callback);
      }
      return synchronousResolve(needs);
    };
    asynchronousResolve = function(needs, callback) {
      var taker;
      if (needs === "") {
        needs = [];
      } else if (typeof needs === "string") {
        needs = [needs];
      }
      taker = {
        needs: needs,
        callback: callback
      };
      if (allNeedsAreMet(needs)) {
        takersToNotify.push(taker);
        if (!alreadyWaitingToNotify) {
          alreadyWaitingToNotify = true;
          setTimeout(notifyTakers);
          return timeoutCount++;
        }
      } else {
        return waitingTakers.push(taker);
      }
    };
    synchronousResolve = function(needs) {
      var i, len, n, o;
      if (typeof needs === "string") {
        return made[needs];
      } else {
        o = {};
        for (i = 0, len = needs.length; i < len; i++) {
          n = needs[i];
          o[n] = made[n];
        }
        return o;
      }
    };
    notifyTakers = function() {
      var i, len, queue, results, taker;
      alreadyWaitingToNotify = false;
      queue = takersToNotify;
      takersToNotify = [];
      results = [];
      for (i = 0, len = queue.length; i < len; i++) {
        taker = queue[i];
        results.push(notify(taker));
      }
      return results;
    };
    notify = function(taker) {
      var name, resolvedNeeds;
      resolvedNeeds = (function() {
        var i, len, ref, results;
        ref = taker.needs;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          name = ref[i];
          results.push(made[name]);
        }
        return results;
      })();
      return taker.callback.apply(null, resolvedNeeds);
    };
    addListener = function(eventName) {
      var handler;
      return window.addEventListener(eventName, handler = function(eventObject) {
        window.removeEventListener(eventName, handler);
        Make(eventName, eventObject);
        return void 0;
      });
    };
    addListener("beforeunload");
    addListener("click");
    addListener("unload");
    switch (document.readyState) {
      case "loading":
        addListener("DOMContentLoaded");
        return addListener("load");
      case "interactive":
        Make("DOMContentLoaded");
        return addListener("load");
      case "complete":
        Make("DOMContentLoaded");
        return Make("load");
      default:
        throw new Error("Unknown document.readyState: " + document.readyState + ". Cannot setup Take&Make.");
    }
  })();
}
