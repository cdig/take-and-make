gulp = require "gulp"
gulp_coffee = require "gulp-coffee"
gulp_concat = require "gulp-concat"


gulp.task "coffee", ()->
  gulp.src "source/**/*.coffee"
    .pipe gulp_concat "scripts.coffee"
    .pipe gulp_coffee()
    .pipe gulp.dest "dist"


gulp.task "default", ["coffee"]
