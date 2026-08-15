#import "@local/lambda:0.1.1": thesis, note-block

// ── Word / character counts (shown on the cover) ────────────────────
#import "@preview/wordometer:0.1.5": word-count, total-words, total-characters
#show: word-count

// ── Abbreviations ────────────────────────────────────────────────────
#import "@preview/abbr:0.3.1"
#show: abbr.show-rule
#abbr.make(
  ("NSAS", "North Sea Autumn Spawning"),
)

// ─────────────────────────────────────────────────────────────────────
#show: thesis.with(
  // ── Document metadata ──
  title: "Regime-shift dynamics of the North Sea Autumn Spawning Herring (Clupea harengus) and its manifestation in individual spawning components.",
  authors: (
    (name: "Finn Linus Krauss", affils: (1,), corresponding: true),
    (name: "Dr. Alexandra Blöcker", affils: (1,)),
  ),
  affiliations: (
    (id: 1, text: "Institute of Marine Ecosystem and Fishery Science (IMF), Universität Hamburg, Hamburg, Germany"),
  ),

  // ── Cover page (manuscript style) ──
  cover: true,
  cover-style: "article",
  word-count: total-words,
  character-count: total-characters,

  // ── Front-matter info bar ──
  email: ("finn.linus.krauss@imbrsea.eu",),

  // ── Abstract ──
  abstract: [
    The @NSAS herring (_Clupea harengus_) has experienced multiple regime shifts throughout its history, but the spatial manifestation of these transitions across individual spawning components remains poorly understood.

    This study investigated regime shift dynamics in the NSAS herring stock and its four spawning components (Shetland-Orkney, Buchan, Banks, and Downs) using a comprehensive analytical framework examining abrupt shifts in biomass, hysteresis in response to fishing pressure, and non-stationary stock-recruitment relationships.
  ],
  keywords: "regime shifts, North Sea herring, spawning components, stock-recruitment relationships, spatial heterogeneity",

  // ── Running head / footer ──
  short-author: "Krauss",
  short-title: "NSAS Herring Regime Shifts",
  foot-info: "M.Sc Thesis",
  university: "Universität Hamburg",

  // ── Feature toggles ──
  show-abstract: true,
  show-outline: true,
  header-footer: true,
  columns: 1,
)

// ═════════════════════════════════════════════════════════════════════
// CONTENT
// ═════════════════════════════════════════════════════════════════════

= Introduction

The North Sea presents a highly productive and dynamic ecosystem with a
rich history of fisheries having key economic and cultural impacts. Replace this placeholder text with your actual introduction.

The four recognized spawning components of NSAS herring are shown in @fig:component_map.

#figure(
  image("../plots/component_map.png", width: 100%),
  caption: [Map of the North Sea with recognized NSAS herring spawning components
    (Shetland-Orkney, Buchan, Banks, and Downs).],
) <fig:component_map> 

= Methods

== Data Sources

== Analytical Framework

=== Changepoint Analysis

=== Stock-Recruitment Relationships

=== Environmental Drivers

= Results

== Full-Stock Analysis

== Component-Level Analysis

#note-block(title: "title")[
  Northern components (Shetland-Orkney, Buchan) dominated the 1980s recovery phase.
]

= Discussion

= Conclusion

// ── References ────────────────────────────────────────────────────────
#colbreak()
#bibliography("refs.bib", style: "apa")

// ── Appendix ──────────────────────────────────────────────────────────
#colbreak()
#set figure(numbering: n => "S" + str(n))
#counter(figure).update(0)
#counter(table).update(0)
#set heading(numbering: none)

= Appendix
