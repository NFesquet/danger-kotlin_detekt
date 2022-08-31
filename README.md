### kotlin_detekt

Detekt files of a gradle based Android project.
This is done using the Android's [Detekt](https://github.com/arturbosch/detekt) tool.
Results are passed out as tables in markdown.

<blockquote>Running KotlinDetekt with its basic configuration
  <pre>
kotlin_detekt.detekt</pre>
</blockquote>

<blockquote>Running KotlinDetekt with a specific gradle task
  <pre>
kotlin_detekt.gradle_task = "detektCheckMyFlavorDebug"
kotlin_detekt.detekt</pre>
</blockquote>

<blockquote>Running KotlinDetekt for a specific severity level and up
  <pre>
# options are ["warning", "error"]
kotlin_detekt.severity = "error"
kotlin_detekt.detekt</pre>
</blockquote>



#### Attributes

`report_file` - Location of Detekt report file
If your Detekt task outputs to a different location, you can specify it here.
Defaults to "build/reports/detekt/detekt-checkstyle.xml".

`gradle_task` - Custom gradle task to run.
This is useful when your project has different flavors.
Defaults to "detektCheck".

`severity` - Defines the severity level of the execution.
Selected levels are the chosen one and up.
Possible values are "Warning", "Error" or "Fatal".
Defaults to "Warning".

`filtering` - Enable filtering
Only show messages within changed files.

Additionally, you can further filter to only the modified lines by setting the `filtering_lines` parameter to `true`.

`skip_gradle_task` - Skip gradle task




#### Methods

`detekt` - Calls Detekt task of your gradle project.
It fails if `gradlew` cannot be found inside current directory.
It fails if `severity` level is not a valid option.
It fails if `xmlReport` configuration is not set to `true` in your `build.gradle` file.
