(function() {
  (function() {
    var EVENTS, allNeedsAreMet, alreadyChecking, angularModule, checkWaitingTakers, eventName, i, len, made, makeHandler, notify, register, resolve, results, waitingTakers;
    EVENTS = ["beforeunload", "click", "load", "unload"];
    made = {};
    waitingTakers = [];
    alreadyChecking = false;
    if (window.angular != null) {
      angularModule = angular.module("TakeAndMake", []);
    }
    window.Make = function(name, value) {
      if (value == null) {
        value = name;
      }
      if (name != null) {
        register(name, value);
      }
      return made;
    };
    window.Take = function(needs, callback) {
      if (needs != null) {
        resolve(needs, callback);
      }
      return waitingTakers;
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
      if (made[name] != null) {
        throw new Error("You may not Make() the same name twice: " + name);
      }
      made[name] = value;
      if (angularModule != null) {
        angularModule.constant(name, value);
      }
      return checkWaitingTakers();
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
      var taker;
      if (typeof needs === "string") {
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
    makeHandler = function(eventName) {
      var handler;
      return handler = function(eventObject) {
        window.removeEventListener(eventName, handler);
        Make(eventName, eventObject);
        return void 0;
      };
    };
    results = [];
    for (i = 0, len = EVENTS.length; i < len; i++) {
      eventName = EVENTS[i];
      results.push(window.addEventListener(eventName, makeHandler(eventName)));
    }
    return results;
  })();

}).call(this);
