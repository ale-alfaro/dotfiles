- [ ] Add Reminder support to Linux! Script below on how to script it 🛫 2026-03-02


```python
#!/usr/bin/python3

import argparse
import sys

from gi.repository import Gio

parser = argparse.ArgumentParser(description="Show GNotification")
group = parser.add_mutually_exclusive_group()
group.add_argument('-i', '--icon-name', default=None, dest='icon_name')
group.add_argument('-p', '--icon-path', default=None, dest='icon_path')
group.add_argument('-u', '--icon-uri', default=None, dest='icon_uri')
parser.add_argument('-a', '--application-id', default='org.gnome.Nautilus', dest='app_id')
parser.add_argument('title', nargs='?', default='Test GNotification')
parser.add_argument('body', nargs='?')
options = parser.parse_args()
print(options)

def app_activated(app):
    notification = Gio.Notification.new(options.title)
    notification.set_body(options.body)
    if options.icon_name:
        notification.set_icon(Gio.ThemedIcon.new(options.icon_name))
    elif options.icon_path:
        notification.set_icon(Gio.FileIcon.new(Gio.File.new_for_path(options.icon_path)))
    elif options.icon_uri:
        notification.set_icon(Gio.FileIcon.new(Gio.File.new_for_uri(options.icon_uri)))

    app.send_notification('notification-id', notification)
    app.get_dbus_connection().flush_sync(None)

# Needs the desktop app-id, in the org.foo.bar form
#app = Gio.Application.new("gnome-calculator", Gio.ApplicationFlags.FLAGS_NONE)
app = Gio.Application.new(options.app_id, Gio.ApplicationFlags.FLAGS_NONE)
app.connect('activate', app_activated)
app.run(None)

```