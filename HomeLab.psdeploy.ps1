# This is just a stub file for now. Doesn't do anything of consequence currently.
Deploy 'Deploy HomeLab module' {
    By Filesystem {
        FromSource '.\HomeLab\'
        To 'C:\temp'
        Tagged Prod
    }
}
