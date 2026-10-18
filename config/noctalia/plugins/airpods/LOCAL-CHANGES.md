Vendored from the installed harveywuk/airpods 1.0.0 community plugin (MIT).
The upstream README and manifest retain its authorship and project links.

Local change: match the control-center calendar/media section cards with a
`surface_variant/0.62` fill, `outline` border (1 px), 12 px rounded corners and
12 px padding. These match Flex::setCardStyle and the glass card opacity over
the transparent bar. Only the background is translucent; text and controls
retain their theme roles and opacity in light and dark modes.

The panel opens horizontally centered at the top of the screen, without
vertical centering or anchoring to the clicked bar icon.


Home Manager installs this directory into Noctalia's local plugin directory,
which takes precedence over downloaded copies of the same plugin ID. Upstream
updates must be merged into this vendored copy deliberately.
