module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Nicolas Fesquet/danger-kotlin_detekt
  # @tags monday, weekends, time, rattata
  #
  class DangerKotlinDetekt < Plugin
    SEVERITY_LEVELS = ["warning", "error"]

    # Location of Detekt report file
    # If your Detekt task outputs to a different location, you can specify it here.
    # Defaults to "build/reports/detekt/detekt-checkstyle.xml".
    # @return [String]
    attr_accessor :report_file
    # A getter for `report_file`.
    # @return [String]
    def report_file
      return @report_file || 'build/reports/detekt/detekt-checkstyle.xml'
    end

    # Custom gradle task to run.
    # This is useful when your project has different flavors.
    # Defaults to "detektCheck".
    # @return [String]
    attr_accessor :gradle_task

    # Defines the severity level of the execution.
    # Selected levels are the chosen one and up.
    # Possible values are "Warning", "Error" or "Fatal".
    # Defaults to "Warning".
    # @return [String]
    attr_writer :severity

    # Enable filtering
    # Only show messages within changed files.
    attr_accessor :filtering

    # Skip gradle task
    attr_accessor :skip_gradle_task

    # Calls Detekt task of your gradle project.
    # It fails if `gradlew` cannot be found inside current directory.
    # It fails if `severity` level is not a valid option.
    # It fails if `xmlReport` configuration is not set to `true` in your `build.gradle` file.
    # @return [void]
    #
    def detekt(inline_mode: false)
      if !skip_gradle_task && !gradlew_exists?
        fail("Could not find `gradlew` inside current directory")
        return
      end

      unless SEVERITY_LEVELS.include?(severity)
        fail("'#{severity}' is not a valid value for `severity` parameter.")
        return
      end

      system "./gradlew #{gradle_task || 'detektCheck'}" unless skip_gradle_task

      unless File.exist?(report_file)
        fail("Detekt report not found at `#{report_file}`. "\
          "Have you forgot to add `xmlReport true` to your `build.gradle` file?")
      end

      issues = read_issues_from_report
      filtered_issues = filter_issues_by_severity(issues)

      if inline_mode
        # Report with inline comment
        send_inline_comment(filtered_issues)
      else
        message = message_for_issues(filtered_issues)
        markdown("### Detekt found issues\n\n" + message) unless message.to_s.empty?
      end
    end

    # A getter for `severity`, returning "warning" if value is nil.
    # @return [String]
    def severity
      @severity || SEVERITY_LEVELS.first
    end

    private

    def read_issues_from_report
      file = File.open(report_file)

      require 'oga'
      report = Oga.parse_xml(file)

      report.xpath('//error')
    end

    def filter_issues_by_severity(issues)
      issues.select do |issue|
        severity_index(issue.get("severity")) >= severity_index(severity)
      end
    end

    def severity_index(severity)
      SEVERITY_LEVELS.index(severity) || 0
    end

    def message_for_issues(issues)
      message = ""

      SEVERITY_LEVELS.reverse.each do |level|
        filtered = issues.select{|issue| issue.get("severity") == level}
        message << parse_results(filtered, level) unless filtered.empty?
      end

      message
    end

    def parse_results(results, heading)
      target_files = (git.modified_files - git.deleted_files) + git.added_files
      dir = "#{Dir.pwd}/"
      count = 0
      message = ""

      results.each do |r|
        location = r.parent
        filename = location.get('name').gsub(dir, "")
        next unless !filtering || (target_files.include? filename)
        line = r.get('line') || 'N/A'
        reason = r.get('message')
        count += 1
        message << "`#{filename}` | #{line} | #{reason} \n"
      end
      if count != 0
        header = "#### #{heading} (#{count})\n\n"
        header << "| File | Line | Reason |\n"
        header << "| ---- | ---- | ------ |\n"
        message = header + message
      end

      message
    end


    # Send inline comment with danger's warn or fail method
    #
    # @return [void]
    def send_inline_comment (issues)
      target_files = (git.modified_files - git.deleted_files) + git.added_files
      dir = "#{Dir.pwd}/"
      SEVERITY_LEVELS.reverse.each do |level|
        filtered = issues.select{|issue| issue.get("severity") == level}
        next if filtered.empty?
        filtered.each do |r|
          location = r.parent
          filename = location.get('name').gsub(dir, "")
          next unless !filtering || (target_files.include? filename)
          line = (r.get('line') || "0").to_i
          send(level === "warning" ? "warn" : "fail", r.get('message'), file: filename, line: line)
        end
      end
    end

    def gradlew_exists?
      `ls gradlew`.strip.empty? == false
    end
  end
end
