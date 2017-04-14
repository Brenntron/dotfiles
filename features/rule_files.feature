Feature: Rule Files Sync
  rule sync (from svn) of rule files

  Scenario:
    When I "POST" the url "/rule_sync/rule_files?filename=%20%09%20%20rules%2Ffile-java.rules%20%09%20%2Cvery%2Fdeep%2Fdeep.rules%2C%20%09%20%0A%20%09%20so_rules%2Ffile-java.rules%20%09%20"

