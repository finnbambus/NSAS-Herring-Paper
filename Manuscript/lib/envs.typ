// ─── CUSTOM ENVIRONMENTS ────────────────────────────────────────────

#import "theme.typ": accent, accent-bg, font-sans

#let rho-box(title: none, body) = {
  box(
    fill: accent-bg,
    radius: 2pt,
    inset: (x: 6pt, y: 5pt),
    width: 100%,
    {
      if title != none {
        text(fill: accent, weight: "bold", font: font-sans, title)
        v(4pt)
      }
      set text(fill: accent, size: 9pt)
      body
    },
  )
}

#let info-block(body) = rho-box(title: "Information", body)
#let note-block(body) = rho-box(title: "Note", body)

#let dropcap(letter, rest) = {
  text(fill: accent, weight: "bold", size: 25pt, font: font-sans, letter)
  h(0.15em)
  rest
}