ruleset io.picolabs.slack {
  meta {
    name "Slack integration"
    description <<
      Provide incoming webhook notification to a slack channel.
    >>
    configure using 
      "team_key" = "none"
      "user_key" = "none"
      "webhook_key" = "none"
    provides slack_notification
  }
  global {
    slack_notification = defaction(channel,message) {
      the_body = <<{ "channel": "##{channel}", "text": "#{message}" }>>
      the_keys = <<#{team_key}/#{user_key}/#{webhook_key}>>
      the_url = <<https://hooks.slack.com/services/#{the_keys}>>
      http:post(the_url, body = the_body) setting(postResult)
      returns(postResult)
    }
  }
}
