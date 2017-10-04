ruleset io.picolabs.tag.enMotion {
  meta {
    name "enMotion paper towel dispenser"
    description <<
        Virtual representation, digital twin, or device shadow of one enMotion paper towel dispenser.
    >>
    author "BAC"
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
  }
  rule tag_registration {
    select when tag registration
    pre {
      id = event:attr("id");
      message = "Tag registered for " + id;
    }
    send_directive("registered",event:attrs());
    fired {
      ent:tag_id := id;
      ent:status := "ok";
      ent:notified := "";
      raise journal event "new_entry" attributes {"memo": message };
    }
  }
  rule enMotion_repaired_details {
    select when enMotion repaired
    always {
      ent:repair_tech := event:attrs("tech");
      ent:repair_details := event:attrs("details");
    }
  }
  rule enMotion_repaired {
    select when   enMotion repaired
           and    tag scanned id re#.*# setting(id)
           within 1 minute
    pre {
      message = "Repair by " + ent:repair_tech + ": " + ent:repair_details;
    }
    fired {
      ent:status := "ok";
      ent:notified := "";
      raise journal event "new_entry" attributes {"memo": message };
      last;
    }
  }
  rule tag_scanned {
    select when tag scanned
    pre {
      timestamp = time:now();
      options = event:attrs().put("timestamp",timestamp);
    }
    send_directive("problem reported",options);
    fired {
      ent:status := "problem";
      ent:lastScan := options;
      raise tag event "problem_reported" attributes options;
    }
  }
  rule tag_problem_reported {
    select when tag problem_reported
    pre {
      timestamp = event:attr("timestamp");
      already_notified = ent:notified != "";
      message = "Problem reported";
    }
    if not already_notified then every {
      http:post("https://hooks.slack.com/services/SLACK1/SLACK2/WEBHOOKID",
        body = <<{ "channel": "#wovyn",>>
             + << "text": "The paper towel dispenser at #{ent:tag_id} is not working" }>>)
        setting(postResult);
      send_directive("postResult", {"postResult": postResult.klog("postResult")});
    }
    fired {
      ent:notified := timestamp;
      raise journal event "new_entry" attributes { "memo": message };
    }
  }
}
