const fs = require('fs')
const gulp = require('gulp')
const zip = require('gulp-zip')
const clean = require('gulp-clean')

const clientAddonFolder = 'E:\\World of Warcraft\\Interface\\AddOns'
const base = { base: '.' }

const extractVersion = (tocFile) => {
	const versionContents = fs.readFileSync(tocFile)
	const versionRegex = /\d+\.\d+\.\d+/;
	const matches = versionRegex.exec(versionContents);

	return matches.length ? matches[0] : '';
};

gulp.task('find-my-buddy', () => {
	const addonName = 'FindMyBuddy'
	const version = extractVersion(`${addonName}/${addonName}.toc`)
	const files = `${addonName}/**/*`
	const zipFileName = `${addonName}-${version}.zip`
	
	const cleanZip = gulp.src(zipFileName)
		.pipe(clean())

	const zipFiles = gulp.src([files], base)
		.pipe(zip(zipFileName))
		.pipe(gulp.dest('.'))
	
	const deployFiles = gulp.src([files], base)
		.pipe(gulp.dest(clientAddonFolder))

	return [cleanZip, zipFiles, deployFiles]
})

gulp.task('default', ['find-my-buddy'])