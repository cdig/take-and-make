// Generated by CoffeeScript 2.5.1
// Since this is typically the first bit of code included in our big compiled and
// concatenated JS files, this is a great place to demand strictness. CoffeeScript
// does not add strict on its own, but it will permit and enforce it.
"use strict";
var DebugTakeMake, Make, Take;

if (!((typeof Take !== "undefined" && Take !== null) || (typeof Make !== "undefined" && Make !== null))) {
  // We declare our globals such that they're visible everywhere within the current scope.
  // This allows for namespacing — all things within a given scope share a copy of Take & Make.
  Take = null;
  Make = null;
  DebugTakeMake = null;
  (function() {
    var addListener, allNeedsAreMet, alreadyChecking, alreadyWaitingToNotify, asynchronousResolve, checkWaitingTakers, clone, made, notify, notifyTakers, register, resolve, synchronousResolve, takersToNotify, timeoutsNeeded, timeoutsUsed, waitingTakers;
    made = {};
    waitingTakers = [];
    takersToNotify = [];
    alreadyWaitingToNotify = false;
    alreadyChecking = false;
    timeoutsNeeded = 0;
    timeoutsUsed = 0;
    Make = function(name, value = name) {
      if (name == null) {
        // Debug — call Make() in the console to see what we've regstered
        return clone(made);
      }
      // Synchronous register, returns value
      return register(name, value);
    };
    Take = function(needs, callback) {
      if (needs == null) {
        // Debug — call Take() in the console to see what we're waiting for
        return waitingTakers.slice();
      }
      // Synchronous and asynchronous resolve, returns value or object of values
      return resolve(needs, callback);
    };
    DebugTakeMake = function() {
      var base, i, j, len, len1, need, output, ref, waiting;
      output = {
        timeoutsNeeded: timeoutsNeeded,
        timeoutsUsed: timeoutsUsed,
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
        throw new Error(`You may not Make() the same name twice: ${name}`);
      }
      made[name] = value;
      checkWaitingTakers();
      return value;
    };
    checkWaitingTakers = function() {
      var i, index, len, taker;
      if (alreadyChecking) { // Prevent recursion from Make() calls inside notify()
        return;
      }
      alreadyChecking = true;
// Depends on `waitingTakers`
// Comments below are to help reason through the (potentially) recursive behaviour
      for (index = i = 0, len = waitingTakers.length; i < len; index = ++i) {
        taker = waitingTakers[index];
        if (allNeedsAreMet(taker.needs)) { // Depends on `made`
          waitingTakers.splice(index, 1); // Mutates `waitingTakers`
          notify(taker); // Calls to Make() or Take() will mutate `made` or `waitingTakers`
          alreadyChecking = false;
          return checkWaitingTakers(); // Restart: `waitingTakers` (and possibly `made`) were mutated
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
        // We always try to resolve both synchronously and asynchronously
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
        timeoutsNeeded++;
        if (!alreadyWaitingToNotify) {
          alreadyWaitingToNotify = true;
          setTimeout(notifyTakers); // Preserve asynchrony
          return timeoutsUsed++;
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
      var i, len, queue, taker;
      alreadyWaitingToNotify = false;
      queue = takersToNotify;
      takersToNotify = [];
      for (i = 0, len = queue.length; i < len; i++) {
        taker = queue[i];
        notify(taker);
      }
      return null;
    };
    notify = function(taker) {
      var resolvedNeeds;
      resolvedNeeds = taker.needs.map(function(name) {
        return made[name];
      });
      return taker.callback.apply(null, resolvedNeeds);
    };
    // IE11 doesn't support Object.assign({}, obj), so we just use our own
    clone = function(obj) {
      var k, out, v;
      out = {};
      for (k in obj) {
        v = obj[k];
        out[k] = v;
      }
      return out;
    };
    // We want to add a few handy one-time events.
    // However, we don't know if we'll be running in a browser, or in node.
    // Thus, we look for the presence of a "window" object as our clue.
    if (typeof window !== "undefined" && window !== null) {
      addListener = function(eventName) {
        var handler;
        return window.addEventListener(eventName, handler = function(eventObject) {
          window.removeEventListener(eventName, handler);
          Make(eventName, eventObject);
          return void 0; // prevent unload from opening a popup
        });
      };
      addListener("beforeunload");
      addListener("click");
      addListener("unload");
      // Since we have a window object, it's probably safe to assume we have a document object
      switch (document.readyState) {
        case "loading":
          addListener("DOMContentLoaded");
          addListener("load");
          break;
        case "interactive":
          Make("DOMContentLoaded");
          addListener("load");
          break;
        case "complete":
          Make("DOMContentLoaded");
          Make("load");
          break;
        default:
          throw new Error(`Unknown document.readyState: ${document.readyState}. Cannot setup Take&Make.`);
      }
    }
    // Finally, we're ready to hand over control to module systems
    if (typeof module !== "undefined" && module !== null) {
      return module.exports = {
        Take: Take,
        Make: Make,
        DebugTakeMake: DebugTakeMake
      };
    }
  })();
}
