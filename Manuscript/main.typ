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

#note-block(title: "Methods adjustments: making BCP changepoint detection reliable")[
  Changepoints in SSB are identified by combining CPT (BinSeg, MBIC penalty)
  with BCP (Bayesian posterior changepoint probability). `bcp()` is called
  with its published defaults (500 MCMC iterations, no forced seed), matching
  Blöcker et al. (2023), whose framework this study follows. Two problems with
  a single such call, both confirmed empirically rather than assumed, required
  adjustment:

  + *A single unseeded run is a noisy point estimate.* Re-running with a
    different seed can change which years cross the detection threshold.
    Fixed by running `bcp()` across 100 seeds per series and reporting, per
    year, the fraction of seeds whose posterior probability exceeds 0.5; a
    year counts as changepoint-supported only when that fraction itself
    clears the region's detection threshold — not when a single run happened
    to.

  + *`bcp()`'s likelihood computation is not numerically scale-invariant.*
    Raw SSB values (order $10^5$–$10^6$) can silently underflow the entire
    posterior to exactly zero for every year, with no warning — traced to
    catastrophic cancellation in the package's C++ implementation. This
    produces a result indistinguishable in output from "no changepoint
    detected," but is a floating-point artifact: the same data, minimally
    rescaled, recovers strong posterior support. No single fixed rescaling is
    safe as a blanket rule (a transform that repairs one series can silently
    re-break a different one that was already fine raw), so affected series
    are retried against a small fixed panel of standard reconditioning
    transforms and the sweep runs on the first one that clears a probe check.

  A further consistency adjustment: CPT's search budget (`Q`, the maximum
  number of candidate changepoints) and BCP's detection threshold were
  previously set differently for the full stock (`Q`=6, threshold 0.5) than
  for the four spawning components (`Q`=6, threshold 0.7) — an inherited,
  unjustified inconsistency. The threshold is now 0.5 throughout; `Q` is
  scaled to series length ($6 times 53/79 approx 4$ for the components, which
  span 1972–2024, against the full stock's 1947–2025) so changepoint search
  density is comparable rather than requesting the same absolute count from a
  substantially shorter series.

  Together these changes reversed two false negatives that predate this
  correction and are unrelated to any data revision: Buchan and Downs were
  both previously reported as having no BCP-supported changepoints, which
  turns out to be the underflow artifact above, confirmed by rerunning the
  exact pre-revision data - both components have real, well-supported
  changepoints once corrected (Results, @sec:component-analysis).
]

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

Combining CPT (BinSeg) and BCP changepoint detection identifies three
consensus regime shifts in NSAS herring SSB since 1947: 1966, 1983, and
2000. These match the changepoints reported for herring by Blöcker et al.
(2023), whose framework this study follows, and — for 2000 specifically — are
corroborated independently by two other, methodologically unrelated analyses:
a breakpoint in the SSB-F hysteresis relationship and a breakpoint in the
stock-recruitment relationship both fall at the same year. 2000 is therefore
the best-evidenced regime shift in the dataset.

Restricted to 1972 onward — the period for which component-level data exists,
and so the only period over which the full stock can be meaningfully compared
against its components (@sec:component-analysis) — none of the three
full-stock phases individually reaches conventional statistical significance
(@tab:full-stock-phases). This matters for interpretation: the aggregate
stock's own trajectory is a comparatively weak, noisy signal, and, as detailed
below, this is largely because it is a sum of much sharper - and often
opposing or sequentially offsetting - component-level trends.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, center),
    table.header([*Phase*], [*Trend (%/year)*], [*Significant?*]),
    [1972 - 1983], [+6.6], [no],
    [1983 - 2000], [+2.1], [no],
    [2000 - 2025], [-0.8], [no],
  ),
  caption: [Full-stock SSB trend by phase, restricted to 1972 onward
    (ordinary least-squares regression on every point within the phase, not
    just its endpoints). None of the three phases is individually significant
    at p < 0.05.],
) <tab:full-stock-phases>

== Component-Level Analysis <sec:component-analysis>

Each spawning component's own consensus changepoints were identified with the
same CPT/BCP procedure, applied separately per component (Methods). Timed
against the full-stock shifts above, no component's own changepoint precedes
a full-stock changepoint - the closest any component comes is coincidence,
never a lead:

- *Shetland-Orkney (SHOR)*: 1983, 1990, 2005 - coincident with the full
  stock's 1983 shift.
- *Banks*: 1982, 1990, 2000, 2005 - the only component coincident with
  _both_ later full-stock shifts (1983 and 2000).
- *Buchan*: a rise visible in the SSB series right at 1983 is not picked up
  as its own formally detected changepoint (it falls inside a longer
  1972-1993 span), but is independently confirmed by a breakpoint in Buchan's
  own stock-recruitment relationship landing on the same year - treated below
  as a real, if informally detected, 1983 shift, alongside the formally
  detected 1993, 2009, 2018.
- *Downs*: 2001, 2011, 2021 - coincident with the full stock's 2000 shift,
  then diverges onto its own timeline entirely.

Subdividing each full-stock phase by whichever component-level changepoints
fall inside it reveals structure the full-stock trend alone hides
(@tab:subphases): components that appear to merely soften or flatten the
full-stock's phase, in fact swing sharply in opposite directions within it.
Buchan is the clearest case: it drives the first half of the 1983-2000
recovery (+18.2%/year, p < 0.01, its share of total stock SSB rising from
7.5% to 40.6%), then sharply reverses in the second half (-46.1%/year,
p < 0.05, share falling back to 19.3%) - giving back its gains well before the
full stock's own recovery phase ends. SHOR shows close to the opposite shape
across the same window: a modest, non-significant rise through 1990 that then
accelerates sharply (+19.3%/year, p < 0.001) through 2000, ending the phase as
the largest single component by share (50%). Banks echoes Buchan's
rise-then-fade shape but more weakly (neither half individually significant).
Downs alone shows no internal split across either of the full stock's early
phases: a single, significant, uninterrupted rise spans 1972-2001 with no
kink at 1983, meaning Downs did not participate in the stock-wide
collapse-recovery cycle the other three components' shifting roles collectively
produce.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([*Component*], [*1983 - ~1990/93*], [*~1990/93 - 2000*],
      [*Share: start*], [*Share: end*]),
    [SHOR], [+8.8%/yr (n.s.)], [+19.3%/yr\*], [41%], [50%],
    [Banks], [+5.5%/yr (n.s.)], [-1.8%/yr (n.s.)], [24%], [6%],
    [Buchan], [+18.2%/yr\*], [-46.1%/yr\*], [40.6%], [19.3%],
    [Downs], table.cell(colspan: 2)[+5.2%/yr\* (single uninterrupted phase)], [\~8%], [\~10%],
  ),
  caption: [SSB trend and share of total stock SSB for each component,
    subdividing the full stock's 1983-2000 recovery phase at each
    component's own internal changepoint (where one falls inside the window).
    \* = p < 0.05. Buchan and SHOR show opposite-shaped trajectories across
    the same window; Downs shows no internal split at all.],
) <tab:subphases>

Since 2000, the pattern continues but with reduced statistical certainty:
SHOR declines significantly and continuously through both 2000-2005 and
2005-2024, Buchan completes a second full rise-fade cycle (rising
significantly into 2018, then declining), Banks shows the weakest version of
the same shape, and Downs' share of the total stock keeps climbing - from
~33% (2001-2011) to ~45% (2021-2024) - even as its own trend loses
significance in two of the three sub-phases. See @sec:discussion-regime for
the interpretation of what this asynchrony implies for reading the full-stock
trend.

= Discussion <sec:discussion-regime>

== Asynchronous components produce an artificially stable full-stock signal

Three of the four components - SHOR, Banks, and Buchan - show the same
underlying shape across the study period: a phase of driving the stock-wide
trend, followed by a phase of fading and losing that role, then repeating.
What differs between them is *timing*: Buchan's drive-fade cycle around the
1983-2000 recovery happens in the first half of the phase and has essentially
reversed by 2000; SHOR's strongest driving is concentrated in the second half
of the same phase and continues into the 2000s; Banks echoes the same shape
weakly and out of step with both. Because these cycles are staggered rather
than synchronized, they partially cancel in the sum: when one component is
building the recovery, another may already be giving it back. This is a
plausible mechanical explanation for why none of the full stock's own phases
individually reaches statistical significance (@tab:full-stock-phases) despite
several of the underlying component-level trends being sharp and significant
in both directions - the aggregate is not stable because the underlying
dynamics are calm, but because asynchronous, opposing component-level swings
average out. Read this way, SHOR, Banks and Buchan are not passively
reflecting a stock-wide regime shift; between them, their staggered handoffs
*constitute* the regime-shift pattern the full-stock analysis detects, while
each component's own considerably more volatile trajectory stays hidden
inside the aggregate.

Downs does not fit this pattern. It is the only component with no internal
reversal across either early phase - a single uninterrupted rise from
1972-2001 - and it is also the component with the weakest independent support
for an actual regime shift: its stock-recruitment relationship shows no
detectable breakpoint at all (the global BIC minimum is zero breaks, both for
the full series and in 45 of 52 LOOCV training subsets — see below), unlike
SHOR, Banks, and Buchan, all three of which have well-supported SRR
breakpoints. Downs' SSB-level changepoints (2001, 2011, 2021) are real and
detectable, but on the weakest evidentiary footing of the four components
when checked against the other independent regime-shift indicators used in
this study (@sec:component-analysis). Combined with its lack of the
drive-fade cycling the other three share, this raises the possibility that
Downs is responding to a largely separate process, decoupled from whatever
drives the shared regime-shift structure in the other three components,
rather than participating in the same stock-wide dynamic on a different
schedule.

This matters for interpreting the full stock's recent trajectory
specifically. Since 2000, Downs' share of total stock SSB has grown from
roughly a third to roughly a half (@sec:component-analysis) while SHOR
declines and Buchan cycles through another drive-fade round. A component that
increasingly dominates the aggregate by weight, whose own dynamics show the
weakest support for participating in the stock's shared regime-shift
structure, is a concerning combination: *the full stock's post-2000
trajectory may increasingly reflect Downs' idiosyncratic behaviour rather
than a genuine stock-wide signal*, even though Downs itself appears to be a
poor representative of whatever process the changepoint and SRR evidence
suggests is shaping the other three components. This is worth stating
plainly as a caution for reading the aggregate stock trend going forward, not
just as a historical curiosity.

#note-block(title: "Downs: weaker regime-shift signal")[
  Downs shows consistently weaker signs of abrupt regime shifts than the other
  components. Its SSB series does have BCP-supported consensus changepoints
  (2001, 2011, 2021, coincident with the full stock's own 2000 shift) — an
  earlier analysis in this project incorrectly reported none, an artifact of a
  numerical underflow bug in the `bcp` package that has since been corrected
  and confirmed not to have been introduced by any data revision. What remains
  true, and is now the stronger basis for the "weaker signal" claim, is that
  Downs' breakpoint SRR model is only weakly supported — the global BIC
  minimum is zero breaks, both for the full series and in 45 of 52 LOOCV
  training subsets. LOOCV instead favors the smooth segmented (threshold)
  models, suggesting gradual nonlinear change in the stock-recruitment
  relationship rather than a discrete shift. Downs' SSB level moves in steps;
  the relationship generating its recruitment does not. (Caveat: Buchan's SSB
  series was also affected by the same underflow bug and is now similarly
  corrected — it does have consensus changepoints, and its SRR breakpoint
  structure is strongly supported, so the "weak shift signal" reading remains
  specific to Downs.)
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
