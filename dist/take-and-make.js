(function() {
  (function() {
    var addListener, allNeedsAreMet, alreadyChecking, asynchronousResolve, checkWaitingTakers, clone, made, notify, register, resolve, synchronousResolve, waitingTakers;
    if ((window.Take != null) || (window.Make != null)) {
      return;
    }
    made = {};
    waitingTakers = [];
    alreadyChecking = false;
    clone = function(o) {
      if (Object.assign != null) {
        return Object.assign({}, o);
      } else {
        return o;
      }
    };
    window.Make = function(name, value) {
      if (value == null) {
        value = name;
      }
      if (name == null) {
        return clone(made);
      } else {
        return register(name, value);
      }
    };
    window.Take = function(needs, callback) {
      if (needs == null) {
        return waitingTakers.slice();
      } else {
        return resolve(needs, callback);
      }
    };
    window.DebugTakeMake = function() {
      var i, j, len, len1, need, ref, unresolved, waiting;
      unresolved = {};
      for (i = 0, len = waitingTakers.length; i < len; i++) {
        waiting = waitingTakers[i];
        ref = waiting.needs;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          need = ref[j];
          if (made[need] == null) {
            if (unresolved[need] == null) {
              unresolved[need] = 0;
            }
            unresolved[need]++;
          }
        }
      }
      return unresolved;
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
        return setTimeout(function() {
          return notify(taker);
        });
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

}).call(this);
