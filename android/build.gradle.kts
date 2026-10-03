allprojects {
    repositories {
        google()
        // Mirror of Google Maven; needed because dl.google.com is not
        // reachable from this machine. Harmless elsewhere (fallback repo).
        maven(url = "https://maven.aliyun.com/repository/google")
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
