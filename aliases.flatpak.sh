# System
startup-configuration() { flatpak run --system --command=startup-configuration --file-forwarding best.ellie.StartupConfiguration "$@"; return $?; }
gradience() { flatpak run --system --command=gradience --file-forwarding com.github.GradienceTeam.Gradience "$@"; return $?; }
czkawka_gui() { flatpak run --system --command=czkawka_gui --file-forwarding com.github.qarmin.czkawka "$@"; return $?; }
flatseal() { flatpak run --system --command=com.github.tchx84.Flatseal --file-forwarding com.github.tchx84.Flatseal "$@"; return $?; }
warehouse() { flatpak run --system --command=warehouse --file-forwarding io.github.flattool.Warehouse "$@"; return $?; }
gearlever() { flatpak run --system --command=gearlever --file-forwarding it.mijorus.gearlever "$@"; return $?; }
menulibre() { flatpak run --system --command=menulibre-wrapper --file-forwarding org.bluesabre.MenuLibre "$@"; return $?; }
mediawriter() { flatpak run --system --command=mediawriter --file-forwarding org.fedoraproject.MediaWriter "$@"; return $?; }
deja-dup() { flatpak run --system --command=deja-dup --file-forwarding org.gnome.DejaDup "$@"; return $?; }
easyeffects() { flatpak run --system --command=easyeffects --file-forwarding com.github.wwmm.easyeffects "$@"; return $?; }
pavucontrol() { flatpak run --system --command=pavucontrol --file-forwarding org.pulseaudio.pavucontrol "$@"; return $?; }
missioncenter() { flatpak run --system --command=missioncenter --file-forwarding io.missioncenter.MissionCenter "$@"; return $?; }
sysd-mng() { flatpak run --system --command=sysd-manager --file-forwarding io.github.plrigaux.sysd-manager "$@"; return $?; }

## GNOME
dconf-editor() { flatpak run --system --command=start-dconf-editor --file-forwarding ca.desrt.dconf-editor "$@"; return $?; }
gnome-logs() { flatpak run --system --command=gnome-logs --file-forwarding org.gnome.Logs "$@"; return $?; }
gnome-extension-manager() { flatpak run --system --command=extension-manager --file-forwarding com.mattjakeman.ExtensionManager "$@"; return $?; }
gnome-extensions-app() { flatpak run --system --command=gnome-extensions-app --file-forwarding org.gnome.Extensions "$@"; return $?; }
gnome-font-viewer() { flatpak run --system --command=gnome-font-viewer --file-forwarding org.gnome.font-viewer "$@"; return $?; }

# Containers
boxbuddy() { flatpak run --system --command=boxbuddy-rs --file-forwarding io.github.dvlv.boxbuddyrs "$@"; return $?; }

# X-GNOME-Utilities.directory
winezgui() { flatpak run --system --command=winezgui --file-forwarding io.github.fastrizwaan.WineZGUI "$@"; return $?; }

# Accessories
peazip() { flatpak run --system --command=peazip --file-forwarding io.github.peazip.PeaZip "$@"; return $?; }
obsidian() { flatpak run --system --command=obsidian.sh --file-forwarding md.obsidian.Obsidian "$@"; return $?; }
QOwnNotes() { flatpak run --system --command=QOwnNotes --file-forwarding org.qownnotes.QOwnNotes "$@"; return $?; }

## GNOME
gnome-calculator() { flatpak run --system --command=gnome-calculator --file-forwarding org.gnome.Calculator "$@"; return $?; }
gnome-calendar() { flatpak run --system --command=gnome-calendar --file-forwarding org.gnome.Calendar "$@"; return $?; }
gnome-clocks() { flatpak run --system --command=gnome-clocks --file-forwarding org.gnome.clocks "$@"; return $?; }
gnome-maps() { flatpak run --system --command=gnome-maps --file-forwarding org.gnome.Maps "$@"; return $?; }
gnome-text-editor() { flatpak run --system --command=gnome-text-editor --file-forwarding org.gnome.TextEditor "$@"; return $?; }
gnome-weather() { flatpak run --system --command=gnome-weather --file-forwarding org.gnome.Weather "$@"; return $?; }

# Virt
virt-manager() { flatpak run --system --command=virt-manager --file-forwarding org.virt_manager.virt-manager "$@"; return $?; }

# Personal
gnome-contacts() { flatpak run --system --command=gnome-contacts --file-forwarding org.gnome.Contacts "$@"; return $?; }
seahorse() { flatpak run --system --command=seahorse --file-forwarding org.gnome.seahorse.Application "$@"; return $?; }
secrets() { flatpak run --system --command=secrets --file-forwarding org.gnome.World.Secrets "$@"; return $?; }
keepassxc() { flatpak run --system --command=keepassxc-wrapper --file-forwarding org.keepassxc.KeePassXC "$@"; return $?; }
keepassxc-cli() { flatpak run --command="keepassxc-cli" --file-forwarding org.keepassxc.KeePassXC "$@"; return $?; }

# Internet
gnome-connections() { flatpak run --system --command=gnome-connections --file-forwarding org.gnome.Connections "$@"; return $?; }
remmina() { flatpak run --system --command=remmina --file-forwarding org.remmina.Remmina "$@"; return $?; }

## Media downloaders
media-downloader() { flatpak run --system --command=io.github.mhogomchungu.media-downloader --file-forwarding io.github.mhogomchungu.media-downloader "$@"; return $?; }
torrhunt() { flatpak run --system --command=torrhunt --file-forwarding com.ktechpit.torrhunt "$@"; return $?; }
qbittorrent() { flatpak run --system --command=qbittorrent --file-forwarding org.qbittorrent.qBittorrent "$@"; return $?; }
tribler() { flatpak run --system --command=tribler --file-forwarding org.tribler.Tribler "$@"; return $?; }

## EMail
betterbird() { flatpak run --system --command=betterbird --file-forwarding eu.betterbird.Betterbird "$@"; return $?; }

## IM
nheko() { flatpak run --system --command=im.nheko.Nheko --file-forwarding im.nheko.Nheko "$@"; return $?; }
session() { flatpak run --system --command=session --file-forwarding network.loki.Session "$@"; return $?; }

## Browsers
chromium() { flatpak run --system --command=chromium --file-forwarding io.github.ungoogled_software.ungoogled_chromium "$@"; return $?; }
librewolf() { flatpak run --system --command=librewolf --file-forwarding io.gitlab.librewolf-community "$@"; return $?; }
floorp() { flatpak run --system --command=floorp --file-forwarding one.ablaze.floorp "$@"; return $?; }
zen() { flatpak run --system --command=launch-script.sh --file-forwarding app.zen_browser.zen "$@"; return $?; }

# Office
gnome-characters() { flatpak run --system --command=gnome-characters --file-forwarding org.gnome.Characters "$@"; return $?; }
marker() { flatpak run --system --command=marker --file-forwarding com.github.fabiocolacio.marker "$@"; return $?; }
pdfarranger() { flatpak run --system --command=pdfarranger --file-forwarding com.github.jeromerobert.pdfarranger "$@"; return $?; }
frog() { flatpak run --system --command=frog --file-forwarding com.github.tenderowl.frog "$@"; return $?; }
xournalpp() { flatpak run --system --command=xournalpp --file-forwarding com.github.xournalpp.xournalpp "$@"; return $?; }
start-zettlr() { flatpak run --system --command=start-zettlr --file-forwarding com.zettlr.Zettlr "$@"; return $?; }
joplin-desktop() { flatpak run --system --command=joplin-desktop --file-forwarding net.cozic.joplin_desktop "$@"; return $?; }
pdfchain() { flatpak run --system --command=pdfchain --file-forwarding net.sourceforge.pdfchain "$@"; return $?; }
evince() { flatpak run --system --command=evince --file-forwarding org.gnome.Evince "$@"; return $?; }
apostrophe() { flatpak run --system --command=apostrophe --file-forwarding org.gnome.gitlab.somas.Apostrophe "$@"; return $?; }
papers() { flatpak run --system --command=papers --file-forwarding org.gnome.Papers "$@"; return $?; }
simple-scan() { flatpak run --system --command=simple-scan --file-forwarding org.gnome.SimpleScan "$@"; return $?; }
okular() { flatpak run --system --command=okular --file-forwarding org.kde.okular "$@"; return $?; }
libreoffice() { flatpak run --system --command=libreoffice --file-forwarding org.libreoffice.LibreOffice "$@"; return $?; }
lyx() { flatpak run --system --command=lyx --file-forwarding org.lyx.LyX "$@"; return $?; }
desktopeditors() { flatpak run --system --command=desktopeditors --file-forwarding org.onlyoffice.desktopeditors "$@"; return $?; }
texworks() { flatpak run --system --command=texworks --file-forwarding org.tug.texworks "$@"; return $?; }

# Dev
codium() { flatpak run --system --command=com.vscodium.codium --file-forwarding com.vscodium.codium "$@"; return $?; }
code() { codium "$@"; return $?; }
alpaca() { flatpak run --system --command=alpaca --file-forwarding com.jeffser.Alpaca "$@"; return $?; }
drawio() { flatpak run --system --command=run.sh --file-forwarding com.jgraph.drawio.desktop "$@"; return $?; }
dbeaver() { flatpak run --system --command=dbeaver --file-forwarding io.dbeaver.DBeaverCommunity "$@"; return $?; }
gaphor() { flatpak run --system --command=gaphor --file-forwarding org.gaphor.Gaphor "$@"; return $?; }
insomnia() { flatpak run --system --command=insomnia --file-forwarding rest.insomnia.Insomnia "$@"; return $?; }

## VG
slade() { flatpak run --system --command=slade3.sh --file-forwarding net.mancubus.SLADE "$@"; return $?; }
godot() { flatpak run --system --command=godot --file-forwarding org.godotengine.Godot "$@"; return $?; }

# Audio
cozy() { flatpak run --system --command=com.github.geigi.cozy --file-forwarding com.github.geigi.cozy "$@"; return $?; }
tenacity() { flatpak run --system --command=tenacity.sh --file-forwarding org.tenacityaudio.Tenacity "$@"; return $?; }

# Video
ghb() { flatpak run --system --command=ghb --file-forwarding fr.handbrake.ghb "$@"; return $?; }
constrict() { flatpak run --system --command=constrict --file-forwarding io.github.wartybix.Constrict "$@"; return $?; }
losslesscut() { flatpak run --system --command=/app/bin/run.sh --file-forwarding no.mifi.losslesscut "$@"; return $?; }
shotcut() { flatpak run --system --command=shotcut --file-forwarding org.shotcut.Shotcut "$@"; return $?; }
vlc() { flatpak run --system --command=vlc --file-forwarding org.videolan.VLC "$@"; return $?; }
obs() { flatpak run --system --command=obs --file-forwarding com.obsproject.Studio "$@"; return $?; }

# 2D
boxy-svg() { flatpak run --system --command=boxy-svg --file-forwarding com.boxy_svg.BoxySVG "$@"; return $?; }
drawing() { flatpak run --system --command=drawing --file-forwarding com.github.maoschanz.drawing "$@"; return $?; }
aseprite() { flatpak run --system --command=aseprite --file-forwarding org.krakua0.Aseprite "$@"; return $?; }
libresprite() { flatpak run --system --command=libresprite --file-forwarding com.github.libresprite.LibreSprite "$@"; return $?; }
pixelorama() { flatpak run --system --command=pixelorama --file-forwarding com.orama_interactive.Pixelorama "$@"; return $?; }
metadata-cleaner() { flatpak run --system --command=metadata-cleaner --file-forwarding fr.romainvigier.MetadataCleaner "$@"; return $?; }
converseen() { flatpak run --system --command=converseen --file-forwarding net.fasterland.converseen "$@"; return $?; }
darktable() { flatpak run --system --command=darktable --file-forwarding org.darktable.Darktable "$@"; return $?; }
loupe() { flatpak run --system --command=loupe --file-forwarding org.gnome.Loupe "$@"; return $?; }
inkscape() { flatpak run --system --command=inkscape --file-forwarding org.inkscape.Inkscape "$@"; return $?; }
krita() { flatpak run --system --command=krita --file-forwarding org.kde.krita "$@"; return $?; }
decoder() { flatpak run --system --command=decoder --file-forwarding com.belmoussaoui.Decoder "$@"; return $?; }

# 3D
f3d() { flatpak run --system --command=f3d --file-forwarding io.github.f3d_app.f3d "$@"; return $?; }
exhibit() { flatpak run --system --command=exhibit --file-forwarding io.github.nokse22.Exhibit "$@"; return $?; }
entrypoint() { flatpak run --system --command=entrypoint --file-forwarding io.github.softfever.OrcaSlicer "$@"; return $?; }
blockbench() { flatpak run --system --command=blockbench-run --file-forwarding net.blockbench.Blockbench "$@"; return $?; }
blender() { flatpak run --system --command=blender --file-forwarding org.blender.Blender "$@"; return $?; }
FreeCAD() { flatpak run --system --command=FreeCAD --file-forwarding org.freecad.FreeCAD "$@"; return $?; }
leocad() { flatpak run --system --command=leocad --file-forwarding org.leocad.LeoCAD "$@"; return $?; }
librecad() { flatpak run --system --command=librecad --file-forwarding org.librecad.librecad "$@"; return $?; }
shadered() { flatpak run --system --command=shadered --file-forwarding org.shadered.SHADERed "$@"; return $?; }
woxel() { flatpak run --system --command=woxel --file-forwarding xyz.woxel.Woxel "$@"; return $?; }

# Gaming Utilities
protonplus() { flatpak run --system --command=protonplus --file-forwarding com.vysp3r.ProtonPlus "$@"; return $?; }

# Games
limo() { flatpak run --system --command=limo --file-forwarding io.github.limo_app.limo "$@"; return $?; }
DoomRunner() { flatpak run --system --command=DoomRunner --file-forwarding io.github.Youda008.DoomRunner "$@"; return $?; }
itch() { flatpak run --system --command=itch-run --file-forwarding io.itch.itch "$@"; return $?; }
veloren() { flatpak run --system --command=veloren-voxygen --file-forwarding net.veloren.veloren "$@"; return $?; }
luanti() { flatpak run --system --command=luanti --file-forwarding org.luanti.luanti "$@"; return $?; }
openmw() { flatpak run --system --command=openmw-launcher --file-forwarding org.openmw.OpenMW "$@"; return $?; }
mc-polly() { flatpak run --system --command=pollymc --file-forwarding org.fn2006.PollyMC "$@"; return $?; }
polly() { mc-polly "$@"; return $?; }
mc-prism() { flatpak run --system --command=prismlauncher --file-forwarding org.prismlauncher.PrismLauncher "$@"; return $?; }
prism() { mc-prism "$@"; return $?; }
gzdoom() { flatpak run --system --command=gzdoom.sh --file-forwarding org.zdoom.GZDoom "$@"; return $?; }
ruffle() { flatpak run --system --command=ruffle --file-forwarding rs.ruffle.Ruffle "$@"; return $?; }

# !not found
baobab() { flatpak run --system --command=baobab --file-forwarding org.gnome.baobab "$@"; return $?; }
cosmic-tweaks() { flatpak run --system --command=cosmic-ext-tweaks --file-forwarding dev.edfloreshz.CosmicTweaks "$@"; return $?; }
snapshot() { flatpak run --system --command=snapshot --file-forwarding org.gnome.Snapshot "$@"; return $?; }
sushi() { flatpak run --system --command=sushi --file-forwarding org.gnome.NautilusPreviewer "$@"; return $?; }

