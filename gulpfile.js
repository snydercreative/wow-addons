const gulp = require('gulp');

gulp.task('find-my-buddy', () => {
	return gulp.src(['FindMyBuddy/**/*'])
		.pipe(gulp.dest('E:\\World of Warcraft\\Interface\\AddOns\\FindMyBuddy'));
})

gulp.task('default', ['find-my-buddy']);