Feature: rule_file_notify
  Test for peake-bridge messages regarding the subversion post-commit hook notification.


  Scenario: Notify that rule files have been committed.
    #When I goto "/bridge/channels/rule-file-notify/messages"
    Given I send and accept JSON
    When I send a POST request to "/bridge/channels/rule-file-notify/messages" with the following:
    """
    {"message":{"filenames": ["trunk/snort-rules/malware.rules"]}}
    """
    Then show me the response
    Then the response status should be "202"

