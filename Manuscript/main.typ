// ════════════════════════════════════════════════════════════════════
// RHO TYPST TEMPLATE  –  main.typ
// Toggle the three booleans below to switch between use cases.
// ════════════════════════════════════════════════════════════════════

#import "lib/rho.typ": *
#import "@preview/wordometer:0.1.5": word-count, total-words, total-characters
#show: word-count

// ── Modular switches ─────────────────────────────────────────────────
#let show-cover-page  = true   // set false for manuscript / paper
#let show-abstract    = true   // set false for quick drafts
#let show-outline     = true   // set false for manuscript / paper
#let two-columns      = false   // set false for thesis / word export
#let show-header-footer = false // set false to disable header and footer

// ── Document metadata ────────────────────────────────────────────────
#let meta = (
  title:           "Regime-shift dynamics of the North Sea Autumn Spawning Herring (Clupea harengus) and its manifestation in individual spawning components.",
  author:          "Finn Linus Krauss",
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
  logo:            none,   // e.g. "figures/university-hamburg.png"
  // Article-header fields
  email:           "finn.linus.krauss@imbrsea.eu",
  defended:        none,
  accepted:        none,
  published:       none,
  doi:             none,
  license:         "Unrestricted use, distribution, and reproduction is permitted in any medium, provided the original author and source are credited.",
)

// ── Abstract content ─────────────────────────────────────────────────
#let my-abstract = [
  The North Sea Autumn Spawning (NSAS) herring (_Clupea harengus_) has experienced
  multiple regime shifts throughout its history, but the spatial manifestation of these
  transitions across individual spawning components remains poorly understood.

  This study investigated regime shift dynamics in the NSAS herring stock and its four
  spawning components (Shetland-Orkney, Buchan, Banks, and Downs) using a comprehensive
  analytical framework examining abrupt shifts in biomass, hysteresis in response to
  fishing pressure, and non-stationary stock-recruitment relationships.
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
#if show-outline {
  show outline: set outline(title: none)
  text(font: font-sans, weight: "bold", fill: accent, size: 11pt)[Contents]
  v(0.4em)
  outline(depth: 3, indent: 1.5em)
  colbreak()
}

// ════════════════════════════════════════════════════════════════════
// CONTENT  –  write your thesis/paper below this line
// ════════════════════════════════════════════════════════════════════

= Introduction

The North Sea presents a highly productive and dynamic ecosystem with a
rich history of fisheries having key economic and cultural impacts. Replace this placeholder text with your actual introduction.

The four recognized spawning components of NSAS herring are shown in @fig:component_map.

#figure(
  image("../plots/component_map.png", width: 50%),
  caption: [Map of the North Sea with recognized NSAS herring spawning components
    (Shetland-Orkney, Buchan, Banks, and Downs).],
) <fig:component_map>

#info-block[
  A *regime shift* is defined as an abrupt, persistent change in ecosystem structure
  and function that persists for multiple years.
]

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

// Reset counters and switch to S-prefixed numbering for supplement
#set figure(
  numbering: n => "S" + str(n),
)
#counter(figure).update(0)
#counter(table).update(0)

= Appendix <appendix>

== Supplementary Information

Supplementary figures and tables go here.

