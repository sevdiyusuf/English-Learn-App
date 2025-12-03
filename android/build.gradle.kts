import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Build output klasörlerini tek bir yerde toplamak için
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Isar ve diğer Android modüllerinde lStar ve namespace problemlerini düzelt
    afterEvaluate {
      if (plugins.hasPlugin("com.android.application") ||
          plugins.hasPlugin("com.android.library")
      ) {
        extensions.configure<BaseExtension> {
          // Uygulamayla aynı seviyeye çek
          compileSdkVersion(34)
          buildToolsVersion("34.0.0")

          // namespace tanımlı değilse group değerinden üret
          if (namespace == null) {
            namespace = project.group.toString()
          }
        }
      }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
