gulp = require "gulp"
gulp_coffee = require "gulp-coffee"


logAndKillError = (err)->
  console.log "\n## Error ##"
  console.log err.toString()
  @emit "end"

paths =
  coffee: "source/take-and-make.coffee"


gulp.task "coffee", ()->
  gulp.src paths.coffee
    .pipe gulp_coffee bare: true
    .on "error", logAndKillError
    .pipe gulp.dest "dist"

gulp.task "default", ["coffee"], ()->
  gulp.watch paths.coffee, ["coffee"]
