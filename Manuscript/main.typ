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

#note-block(title: "Methods caveat: same-year pairing, no larval-to-recruitment lag")[
  All analyses pair assessment values within the same year: the component split
  applies the year-y LAI share to year-y SSB and recruitment, and the
  stock-recruitment models fit R(y) against SSB(y). No explicit lag from the
  larval stage to recruitment is included. Because NSAS herring is an autumn
  spawner aged in winter rings, the recruitment reported in year y likely
  corresponds to the cohort spawned in autumn y−1, so a cohort-consistent pairing
  would use the y−1 LAI share and SSB. We retain the same-year pairing for
  comparability with Blöcker et al. (2023), whose framework this study follows;
  LAI shares change slowly between adjacent years, so the effect of the one-year
  offset is limited. The maturation lag (recruits entering the spawning stock at
  age 2-3) is implicit in the assessment output and is only relevant when
  interpreting the timing of changepoints.
]

= Results

== Full-Stock Analysis

== Component-Level Analysis

#note-block(title: "title")[
  Northern components (Shetland-Orkney, Buchan) dominated the 1980s recovery phase.
]

= Discussion

#note-block(title: "Downs: weaker regime-shift signal")[
  Downs shows consistently weaker signs of abrupt regime shifts than the other
  components, across two independent analyses: (1) BCP detects no changepoints in
  its SSB series (no consensus changepoints), and (2) its breakpoint SRR model is
  only weakly supported — the global BIC minimum is zero breaks, both for the full
  series and in 45 of 52 LOOCV training subsets. LOOCV instead favors the smooth
  segmented (threshold) models, suggesting gradual nonlinear change rather than
  discrete shifts. (Caveat: Buchan also lacks consensus changepoints in SSB, but
  its SRR breakpoint structure is strongly supported — its evidence is mixed, so
  the "weak shift signal" reading is specific to Downs.)
]

#note-block(title: "Beverton-Holt failure supports non-stationarity")[
  The stationary continuous SRR models were included precisely to test whether
  they can describe the data — and they cannot. Beverton-Holt and Ricker fit but
  describe the data poorly wherever they converge, and for Downs the Beverton-Holt
  form is outright incompatible: its saturating shape cannot represent the
  increasing Downs stock-recruitment relationship, and the log-scale fit fails to
  even evaluate on 51 of 52 LOOCV training subsets. This supports the core claim
  that a single continuous stationary model is not suitable for the NSAS SRR.
]

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
