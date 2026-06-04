#import "lib/rho.typ": *
#import "@preview/wordometer:0.1.5": word-count, total-words, total-characters
#show: word-count
#import "@preview/abbr:0.3.0"
#show: abbr.show-rule

// ── Modular switches ─────────────────────────────────────────────────
#let show-cover-page  = true   // set false for manuscript / paper
#let show-abstract    = true   // set false for quick drafts
#let show-outline     = true   // set false for manuscript / paper
#let two-columns      = false   // set false for thesis / word export
#let show-header-footer = true // set false to disable header and footer

// ── Document metadata ────────────────────────────────────────────────
#let meta = (
  title:           "Regime-shift dynamics of the North Sea Autumn Spawning Herring (Clupea harengus) and its manifestation in individual spawning components.",
  authors:         ((name: "Finn Linus Krauss", affils: (1,)),),
  affiliations:    ((id: 1, text: "IMBRsea, Universiteit Gent"),),
  birthday:        "April 10, 2001",
  student_id:      "7468125",
  degree:          "Bachelor of Science",
  major:           "Marine Ecosystems and Fisheries Sciences",
  department:      "Department of Biology",
  faculty:         "Institute of Marine Ecosystem and Fishery Science (IMF)",
  university:      "Universität Hamburg",
  location:        "Hamburg, Germany",
  date:            "April 2026",
  supervisor:      "Dr. Alexandra Blöcker",
  logo:            none,
  email:           ("finn.linus.krauss@imbrsea.eu",),
  defended:        none,
  accepted:        none,
  published:       none,
  doi:             none,
  license:         "Unrestricted use, distribution, and reproduction is permitted in any medium, provided the original author and source are credited.",
)

// ── Abbrevations ─────────────────────────────────────────────────────
#abbr.make(
  ("NSAS", "North Sea Autumn Spawning"),
)

// ── Abstract content ─────────────────────────────────────────────────
#let my-abstract = [
  The @NSAS herring (_Clupea harengus_) has experienced multiple regime shifts throughout its history, but the spatial manifestation of these transitions across individual spawning components remains poorly understood.

  This study investigated regime shift dynamics in the NSAS herring stock and its four spawning components (Shetland-Orkney, Buchan, Banks, and Downs) using a comprehensive analytical framework examining abrupt shifts in biomass, hysteresis in response to fishing pressure, and non-stationary stock-recruitment relationships.
]

#let my-keywords = "regime shifts, North Sea herring, spawning components, stock-recruitment relationships, spatial heterogeneity"

// ════════════════════════════════════════════════════════════════════
// COVER PAGE  (remove by setting show-cover-page = false above)
// ════════════════════════════════════════════════════════════════════

#if show-cover-page {
  show-cover(meta)
}

// ════════════════════════════════════════════════════════════════════
// BODY  – page setup, header/footer, heading styles applied here
// ════════════════════════════════════════════════════════════════════
#show: body => show-layout(
  body,
  column-count:        if two-columns { 2 } else { 1 },
  lead-author:         "Krauss",
  short-title:         "NSAS Herring Regime Shifts",
  foot-info:           "M.Sc Thesis",
  institution:         meta.university,
  show-header-footer:  show-header-footer,
)

// ── First-page title block ────────────────────────────────────────────
#counter(page).update(1)

#show-article-header(
  title:       meta.title,
  date:        [This manuscript compiled on #datetime.today().display("[month repr:long] [day], [year]")],
  abstract:    if show-abstract { my-abstract } else { none },
  keywords:    if show-abstract { my-keywords  } else { none },
  show-info:   false,
  email:       meta.email,
  defended:    meta.defended,
  accepted:    meta.accepted,
  published:   meta.published,
  doi:         meta.doi,
  license:     meta.license,
)

// ── Table of contents (remove by setting show-outline = false above) ──

#set heading(numbering: "1.1")

#show outline.entry.where(level: 1): it => [
  #link(
    it.element.location(),
    it.indented(
      strong(text(fill: black)[#it.prefix()]),
      [#strong(text(fill: accent)[#it.body()])
        #h(1fr)
        #sym.wj
        #strong(text(fill: black)[#it.page()])],),)]

#show outline.entry.where(level: 2): it => [
  #link(it.element.location(),
    it.indented(
      text(fill: black)[#it.prefix()],
      [#text(fill: accent)[#it.body()]
        #box(width: 1fr, it.fill)
        #sym.wj
        #text(fill: black)[#it.page()]],),)]

#show outline.entry.where(level: 3): it => [
  #link(
    it.element.location(),
    it.indented(
      [],[#box(width: 100%)[
          #text(size: 7pt, fill: accent, hyphenate: false)[#it.body()]]],),)]

#if show-outline {
  show outline: set outline(title: none)
  text(font: font-sans, weight: "bold", fill: accent, size: 11pt)[Contents]
  v(0.4em)
  outline(depth: 3, indent: auto)
  colbreak()}

// ════════════════════════════════════════════════════════════════════
// CONTENT  –  write thesis/paper below this line
// ════════════════════════════════════════════════════════════════════

= Introduction

The North Sea presents a highly productive and dynamic ecosystem with a
rich history of fisheries having key economic and cultural impacts. Replace this placeholder text with your actual introduction.

The four recognized spawning components of NSAS herring are shown in @fig:component_map.

#figure(
  image("../plots/component_map.png", width: 100%),
  caption: [Map of the North Sea with recognized NSAS herring spawning components
    (Shetland-Orkney, Buchan, Banks, and Downs).],
) <fig:component_map>

== Background

=== Spawning Components

=== Regime Shifts

= Methods

== Data Sources

== Analytical Framework

=== Changepoint Analysis

=== Stock-Recruitment Relationships

=== Environmental Drivers

= Results

== Full-Stock Analysis

== Component-Level Analysis

#note-block[
  Northern components (Shetland-Orkney, Buchan) dominated the 1980s recovery phase.
]

= Discussion

= Conclusion

// ── References ────────────────────────────────────────────────────────
#colbreak()
#bibliography("refs.bib", style: "apa")

// ── Appendix ──────────────────────────────────────────────────────────
#colbreak()
#set figure(
  numbering: n => "S" + str(n),)
#counter(figure).update(0)
#counter(table).update(0)
#set heading(numbering: none)

= Appendix