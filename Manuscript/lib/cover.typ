// ─── COVER PAGE ───────────────────────────────────────────────────────────────
// Call show-cover(..meta) from main.typ.
// All fields are optional; omit what you don't need.

#import "theme.typ": accent, font-sans, font-serif

#let show-cover(
  title: "",
  author: "",
  email: none,
  birthday: none,
  student-id: none,
  degree: none,
  major: none,
  department: none,
  faculty: none,
  university: none,
  location: none,
  date: none,
  submission-text: none,
  supervisor: none,
  co-supervisor: none,
  logo: none,
) = {
  set page(
    margin: (left: 2.5cm, right: 2.5cm, top: 2.4cm, bottom: 2.4cm),
    numbering: none,
    header: none,
    footer: none,
  )

  let uni-block = {
    set align(left)
    if university != none {
      text(font: font-sans, weight: "bold", size: 14pt, university)
      linebreak()
    }
    if department != none {
      text(font: font-serif, size: 14pt, department)
      linebreak()
    }
    if faculty != none {
      text(font: font-serif, style: "italic", size: 12pt, faculty)
    }
  }

  let logo-block = {
    set align(right)
    if logo != none {
      image(logo, width: 2.2cm)
    } else {
      align(right, box(
        width: 2.2cm,
        height: 2.2cm,
        stroke: 0.6pt + accent,
        inset: 0pt,
        radius: 2pt,
        align(center + horizon, text(
          font: font-sans,
          size: 8pt,
          fill: accent,
          "LOGO",
        )),
      ))
    }
  }

  grid(
    columns: (1fr, 2.6cm),
    column-gutter: 1cm,
    uni-block,
    logo-block,
  )

  v(1fr)

  align(center, {
    set par(justify: false, leading: 0.5em)
    text(
      font: font-sans,
      fill: accent,
      weight: "bold",
      size: 20pt,
      title,
    )
  })

  v(1fr)

  align(center, {
    if submission-text != none {
      text(font: font-serif, size: 10pt, submission-text)
      v(-0.5cm)
    }
    if degree != none {
      text(font: font-sans, weight: "bold", size: 26pt, degree)
      v(-0.5cm)
    }
    if major != none {
      text(font: font-serif, size: 12pt, [in #emph(major)])
    }
  })

  v(1fr)

  let left-col = {
    set align(center)
    text(font: font-sans, weight: "bold", size: 12pt, author)
    if email != none {
      v(0.2cm)
      text(font: font-serif, size: 12pt, email)
    }
    if birthday != none {
      v(0cm)
      text(font: font-sans, weight: "bold", "Born:")
      linebreak()
      text(font: font-serif, style: "italic", birthday)
    }
    if student-id != none {
      v(0cm)
      text(font: font-sans, weight: "bold", "Student ID:")
      linebreak()
      text(font: font-serif, style: "italic", str(student-id))
    }
  }

  let right-col = {
    set align(center)
    if supervisor != none {
      text(font: font-sans, weight: "bold", fill: accent, "Supervisor:")
      linebreak()
      text(font: font-serif, size: 12pt, supervisor)
    }
    if co-supervisor != none {
      v(0cm)
      text(font: font-sans, weight: "bold", fill: accent, "Co-supervisor:")
      linebreak()
      text(font: font-serif, size: 12pt, co-supervisor)
    }
    if location != none {
      v(0cm)
      text(font: font-sans, weight: "bold", location)
    }
    if date != none {
      linebreak()
      text(font: font-serif, style: "italic", date)
    }
  }

  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2cm,
    left-col,
    right-col,
  )
}