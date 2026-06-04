// ─── CUSTOM ENVIRONMENTS ────────────────────────────────────────────
#import "theme.typ": accent, accent-bg, font-sans

#let rho-box(title: none, body) = {
  box(
    fill: accent-bg,
    radius: 2pt,
    inset: (x: 6pt, y: 5pt),
    width: 100%,
    {if title != none {
        text(fill: accent, weight: "bold", font: font-sans, title)
        v(4pt) }
      set text(fill: accent, size: 9pt)
      body}, ) }

#let note-block(body, title: none) = {
  if title != none {
    rho-box(title: title, body)  // ← named
  } else {
    rho-box(body)
  }
}