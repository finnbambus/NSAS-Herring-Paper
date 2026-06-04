// ─── ARTICLE HEADER (title block, abstract, info bar) ─────────────────────────
#import "theme.typ": accent, accent-bg, font-sans, font-serif, text-muted

// ── Keyword line helper ──
#let keywords-line(kws) = {
  set text(size: 8pt, font: font-sans)
  text(weight: "bold", fill: accent, "Keywords: ")
  text(style: "italic", kws) }

// ── Info box (supervisors, dates, DOI, license) ──
#let info-box(
  supervisors: none,
  email:       none,
  submitted:   none,
  defended:    none,
  accepted:    none,
  published:   none,
  doi:         none,
  license:     none,
  ) = {
  set text(size: 7.8pt, font: font-sans)
  if email != none {
  text(fill: accent, weight: "bold", "E-mail: ")
  for (i, addr) in email.enumerate() {
    if i > 0 { text(", ") }
    link("mailto:" + addr)[#addr] }
  linebreak()
  if supervisors != none { text(fill: accent, weight: "bold", "Supervisors: "); supervisors; linebreak() }}
  if doi         != none { text(fill: accent, weight: "bold", "DOI: ");         doi;         linebreak() }
  if submitted   != none { text(fill: accent, weight: "bold", "Submitted: ");   submitted;   h(10pt) }
  if defended    != none { text(fill: accent, weight: "bold", "Defended: ");    defended;    h(10pt) }
  if accepted    != none { text(fill: accent, weight: "bold", "Accepted: ");    accepted;    h(10pt) }
  if published   != none { text(fill: accent, weight: "bold", "Published: ");   published;   linebreak() }
  if license     != none { v(3pt); text(size: 7.5pt, fill: text-muted, license) }
}

// ── Abstract box ──
#let abstract-box(abstract-content, keywords: none) = {
  box(
    fill:   accent-bg,
    radius: 2pt,
    inset:  (x: 6pt, y: 5pt),
    width:  100%,
    {
      text(fill: accent, weight: "bold", size: 9pt, font: font-sans, "Abstract")
      v(4pt)
      set text(size: 8.5pt, font: font-sans)
      abstract-content
      if keywords != none { v(6pt); keywords-line(keywords) } } ) }

// ── Main entry point ──
#let show-article-header(
  title: "",
  authors: (),
  affiliations: (),
  date: none,
  abstract: none,
  keywords: none,
  show-info: true,
  supervisors: none, email: none, submitted: none, defended: none,
  accepted: none, published: none, doi: none, license: none,) = {
  set par(justify: false, leading: 0.4em)
  text(fill: accent, weight: "black", size: 20pt, font: font-sans, title)
  v(-5pt)
  
  if authors.len() > 0 {
  set text(size: 9pt, font: font-sans, weight: "bold")
  authors.map(a => {
    if type(a) == str {
      a
    } else {
      let nums = if type(a.affils) == array { a.affils } else { (a.affils,) }
      let ids = nums.map(n => [#n]).join([, ])
      if ids == none { a.name } else { a.name + super[#ids] } }
  }).join(", ")
  v(-5pt)
}

  if affiliations.len() > 0 {
  set text(size: 8pt, font: font-sans)
  for aff in affiliations {
    text(weight: "bold", str(aff.id) + " ")
    aff.text
    linebreak() }
  v(3pt)
}

  if abstract != none {
    abstract-box(abstract, keywords: keywords)
    v(4pt) }

  if show-info {
    info-box(
      email: email, supervisors: supervisors,
      submitted: submitted, defended: defended,
      accepted: accepted, published: published,
      doi: doi, license: license, ) }

  v(3pt)
  
  if date != none {
    set text(size: 7.5pt, font: font-sans, fill: text-muted)
    date
    v(0pt) }
  
  line(length: 100%, stroke: 0.3pt)
}
