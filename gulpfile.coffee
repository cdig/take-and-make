gulp = require "gulp"
gulp_coffee = require "gulp-coffee"


gulp.task "coffee", ()->
  gulp.src "source/*.coffee"
    .pipe gulp_coffee bare: true
    .pipe gulp.dest "dist"


gulp.task "default", ["coffee"]
