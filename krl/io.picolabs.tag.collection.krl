ruleset io.picolabs.tag.collection {
  meta {
    name "System Tag Router"
    description <<
        Handles all tag scan events and redirects to the resource associated with the tag.
    >>
    author "BAC"
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }
    routingTable = {
      "enMotion": { "rids": "io.picolabs.tag.enMotion;io.picolabs.journal" },
      "sqtg": { "rids": "io.picolabs.sqtg" }
    }
  }
  rule initialize {
    select when wrangler ruleset_added where rids >< meta:rid
    always {
      ent:tags := {};
      raise tags event "initialized";
    }
  }
  rule tag_scanned {
    select when tag scanned where ent:tags >< event:attr("id")
    pre {
      id = event:attr("id");
      eci = ent:tags{[id,"eci"]};
    }
    every {
      event:send({"eci":eci, "domain":"tag", "type":"scanned", "attrs":event:attrs()});
      send_directive("forwarded to "+id,{"eci":eci});
    }
    fired {
      last;
    }
  }
  rule tag_scanned_first_time {
    select when tag scanned
    pre {
      tag_domain = event:attr("tag_domain");
      name = event:attr("id"); // use tag id as pico name
      rids = routingTable{[tag_domain,"rids"]};
      child_specs = { "name": name, "rids": rids };
    }
    fired {
      raise wrangler event "new_child_request" attributes child_specs;
      ent:tag_domain := tag_domain;
    }
  }  
  rule pico_new_child_created {
    select when pico new_child_created
    pre {
      child_id = event:attr("id");
      child_eci = event:attr("eci");
      child_specs = event:attr("rs_attrs");
      id = child_specs{"name"}; // recover tag id from pico name
      entry = { "id": id, "tag_domain": ent:tag_domain };
    }
    every {
      engine:newChannel(child_id,time:now(),"to tag") setting(new_channel);
      send_directive(id + " pico created",{ "eci": new_channel{"id"} });
      event:send({"eci":child_eci, "domain":"tag", "type":"registration", "attrs":entry});
    }
    always {
      ent:tags{id} := entry.put("eci", new_channel{"id"});
      clear ent:tag_domain;
    }
  }
}
