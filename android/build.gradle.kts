import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
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
subprojects {
    if (name == "app") {
        return@subprojects
    }
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByType(LibraryExtension::class.java)
        tasks.withType<KotlinCompile>().configureEach {
            val jvmVersion = android.compileOptions.targetCompatibility
            val jvmTargetString =
                if (jvmVersion == JavaVersion.VERSION_1_8) {
                    "1.8"
                } else {
                    jvmVersion.majorVersion.toString()
                }
            compilerOptions.jvmTarget.set(JvmTarget.fromTarget(jvmTargetString))
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}