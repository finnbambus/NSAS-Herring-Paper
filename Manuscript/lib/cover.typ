#import "theme.typ": accent, font-sans, font-serif
#import "@preview/wordometer:0.1.5": total-words, total-characters

#let show-cover(meta) = {
  set page(
    margin: (left: 2.5cm, right: 2.5cm, top: 2.4cm, bottom: 2.4cm),
    numbering: none,   // ← removes the page number from cover
    header: none,
    footer: none,
  )

  let affil-parts = ()
  if "faculty"    in meta { affil-parts = affil-parts + (meta.faculty,) }
  if "university" in meta { affil-parts = affil-parts + (meta.university,) }
  if "location"   in meta { affil-parts = affil-parts + (meta.location,) }
  let affil-str = affil-parts.join(", ")

  v(1fr)

  align(center, {
    set par(justify: false, leading: 0.6em)
    text(font: font-sans, weight: "bold", size: 24pt, fill: accent ,meta.title)
  })

  v(1fr)

  align(left, {
    let primary = text(font: font-sans, size: 11pt, meta.author) + super("1*")
    let line = if "supervisor" in meta {
      primary + text(font: font-sans, size: 11pt, ", ") + text(font: font-sans, size: 11pt, meta.supervisor) + super("1")
    } else { primary }
    line
  })

  v(0.4cm)
  line(length: 35%)
  v(0.2cm)

  if affil-str != "" {
    text(font: font-serif, size: 9pt, super("1") + " " + affil-str)
    linebreak()
  }

  text(font: font-serif, size: 9pt, {
    super("*") + " Corresponding Author: " + meta.author
    if "email" in meta {
      ", "
      link("mailto:" + meta.email, text(fill: accent, meta.email))
    }
  })

  // Counts auto-resolve to full document totals
  v(0.5cm)
  text(font: font-sans, size: 10pt, "Word count: ")
  text(font: font-sans, size: 10pt, fill: accent, total-words)
  linebreak()
  text(font: font-sans, size: 10pt, "Character count: ")
  text(font: font-sans, size: 10pt, fill: accent, total-characters)
}