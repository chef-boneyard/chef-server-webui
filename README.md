# chef-server-webui

* Documentation: http://docs.opscode.com/
* Tickets/Issues: http://tickets.opscode.com
* IRC: [#chef](irc://irc.freenode.net/chef) and [#chef-hacking](irc://irc.freenode.net/chef-hacking) on Freenode
* Mailing list: http://lists.opscode.com

## Overview ##

The `chef-server-webui` is a simple Rails 3.2 application which talks to the Chef Server
API (aka Erchef) for all back-end data. Installation is easy as the `chef-server-webui`
already comes preconfigured as part of the default chef-server Omnibus package install. The
`chef-server-webui` can also be deployed under any [Rack|http://rack.github.com/] compliant
server.

The following default configuration values can be overriden in your Rails environment
config:

```ruby
config.chef_server_url = "http://127.0.0.1:8000"
config.rest_client_name = "chef-webui"
config.rest_client_key = "/etc/chef-server/webui_priv.pem"
config.admin_user_name =  "admin"
config.admin_default_password = "p@ssw0rd1"
```

## Contributing/Development

Before working on the code, if you plan to contribute your changes, you need to
read the
[Opscode Contributing document](http://wiki.opscode.com/display/chef/How+to+Contribute).

You will also need to set up the repository with the appropriate branches. We
document the process on the
[Working with Git](http://wiki.opscode.com/display/chef/Working+with+git) page
of the Chef wiki.

## Reporting Bugs ##

You can search for known issues in
[Opscode Chef's bug tracker][jira]. Tickets should be filed under the
**CHEF** project with the component set to **"Chef Server"**.

[jira]: http://tickets.opscode.com/browse/CHEF

## License ##

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Copyright:**       | Copyright (c) 2011-2012 Opscode, Inc.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
