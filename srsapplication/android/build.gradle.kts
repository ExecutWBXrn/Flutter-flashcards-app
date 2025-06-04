buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Замініть версії на ті, які ви використовуєте або останні стабільні
        // Версія Android Gradle Plugin, має відповідати тій, що використовується (можна знайти в gradle-wrapper.properties або налаштуваннях проєкту)
        // Наприклад, для Android Studio Iguana | 2023.2.1, AGP може бути 8.2.0 - 8.2.2
        // Для Android Studio Hedgehog | 2023.1.1, AGP може бути 8.1.0 - 8.1.4
        // Перевірте вашу версію AGP!
        classpath("com.android.tools.build:gradle:8.2.0") // ПРИКЛАД ВЕРСІЇ, ПЕРЕВІРТЕ ВАШУ!

        // Версія Kotlin Gradle Plugin
        // Зазвичай визначається через властивість, але для простоти можна вказати напряму.
        // Має відповідати версії Kotlin, яку використовує ваш проєкт
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23") // ПРИКЛАД ВЕРСІЇ, ПЕРЕВІРТЕ ВАШУ!

        // ВАЖЛИВО: залежність для Google Services
        classpath("com.google.gms:google-services:4.4.1") // Або 4.3.15, або інша актуальна стабільна версія
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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