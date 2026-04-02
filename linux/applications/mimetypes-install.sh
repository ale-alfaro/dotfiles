# Copy and sync icon files
mkdir -p ~/.local/share/icons/hicolor/48x48/apps/
cp ~/.local/share/omarchy/applications/icons/*.png ~/.local/share/icons/hicolor/48x48/apps/
gtk-update-icon-cache ~/.local/share/icons/hicolor &>/dev/null

# Copy .desktop declarations
mkdir -p ~/.local/share/applications
cp ~/.local/share/omarchy/applications/*.desktop ~/.local/share/applications/
cp ~/.local/share/omarchy/applications/hidden/*.desktop ~/.local/share/applications/

# Refresh the webapps and TUIs
bash $OMARCHY_PATH/install/packaging/icons.sh
# bash $OMARCHY_PATH/install/packaging/webapps.sh
# bash $OMARCHY_PATH/install/packaging/tuis.sh

update-desktop-database ~/.local/share/applications

# Open directories in file manager
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Open all images with imv
xdg-mime default imv.desktop image/png
xdg-mime default imv.desktop image/jpeg
xdg-mime default imv.desktop image/gif
xdg-mime default imv.desktop image/webp
xdg-mime default imv.desktop image/bmp
xdg-mime default imv.desktop image/tiff

# Open PDFs with the Document Viewer
xdg-mime default org.pwmt.zathura.desktop application/pdf

# Use Chromium as the default browser
xdg-settings set default-web-browser zen.desktop
xdg-mime default zen.desktop x-scheme-handler/http
xdg-mime default zen.desktop x-scheme-handler/https

# Open video files with mpv
xdg-mime default mpv.desktop video/mp4
xdg-mime default mpv.desktop video/x-msvideo
xdg-mime default mpv.desktop video/x-matroska
xdg-mime default mpv.desktop video/x-flv
xdg-mime default mpv.desktop video/x-ms-wmv
xdg-mime default mpv.desktop video/mpeg
xdg-mime default mpv.desktop video/ogg
xdg-mime default mpv.desktop video/webm
xdg-mime default mpv.desktop video/quicktime
xdg-mime default mpv.desktop video/3gpp
xdg-mime default mpv.desktop video/3gpp2
xdg-mime default mpv.desktop video/x-ms-asf
xdg-mime default mpv.desktop video/x-ogm+ogg
xdg-mime default mpv.desktop video/x-theora+ogg
xdg-mime default mpv.desktop application/ogg

# Open text files with nvim
xdg-mime default nvim.desktop text/plain
xdg-mime default nvim.desktop text/english
xdg-mime default nvim.desktop text/x-makefile
xdg-mime default nvim.desktop text/x-c++hdr
xdg-mime default nvim.desktop text/x-c++src
xdg-mime default nvim.desktop text/x-chdr
xdg-mime default nvim.desktop text/x-csrc
xdg-mime default nvim.desktop text/x-java
xdg-mime default nvim.desktop text/x-moc
xdg-mime default nvim.desktop text/x-pascal
xdg-mime default nvim.desktop text/x-tcl
xdg-mime default nvim.desktop text/x-tex
xdg-mime default nvim.desktop application/x-shellscript
xdg-mime default nvim.desktop text/x-c
xdg-mime default nvim.desktop text/x-c++
xdg-mime default nvim.desktop application/xml
xdg-mime default nvim.desktop text/xml

# Use Thunderbird for for mail and calendar links
xdg-mime default thunderbird.desktop x-scheme-handler/mailto
xdg-mime default thunderbird.desktop x-scheme-handler/mid
xdg-mime default thunderbird.desktop x-scheme-handler/webcal
xdg-mime default thunderbird.desktop x-scheme-handler/ics
