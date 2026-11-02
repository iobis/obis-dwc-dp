// Minimal slide theme.
// Spacing, type scale, and gray hierarchy follow gh-minimal-slides.
// No badges, monospace labels, terminal frames, or status colors.

#import "@preview/touying:0.7.4": *

#let _font = ("Inter", "Helvetica Neue", "Source Sans 3")

#let _defaults = (
  title: none,
  bg: rgb("#ffffff"),
  ink: rgb("#1f2328"),
  muted: rgb("#59636e"),
  faint: rgb("#818b98"),
  link: rgb("#a84832"),
  font: _font,
  hero: 60pt,
  title-size: 36pt,
  body: 23pt,
  meta: 15pt,
  pad-x: 88pt,
)

#let _state = state("plain-theme", _defaults)

#let _header() = context {
  let ctx = _state.get()
  let n = utils.slide-counter.get().first()
  block(width: 100%)[
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(size: ctx.meta, fill: ctx.muted, ctx.title),
      text(size: ctx.meta, fill: ctx.faint, str(n)),
    )
  ]
}

#let _frame(body) = context {
  let ctx = _state.get()
  block(
    width: 100%,
    height: 100%,
    inset: (top: 36pt, bottom: 48pt, x: ctx.pad-x),
  )[
    #grid(
      rows: (auto, 1fr),
      row-gutter: 56pt,
      _header(),
      body,
    )
  ]
}

#let _title(body) = context {
  let ctx = _state.get()
  block(width: 100%)[
    #set text(
      size: ctx.title-size,
      weight: 600,
      fill: ctx.ink,
      tracking: -0.8pt,
    )
    #set par(leading: 0.42em)
    #body
  ]
}

#let eyebrow(body) = context {
  let ctx = _state.get()
  block(below: 12pt)[
    #text(size: ctx.meta, fill: ctx.muted, weight: 500, body)
  ]
}

#let columns(left, right) = grid(
  columns: (1fr, 1fr),
  gutter: 56pt,
  left,
  right,
)

#let cover(
  title: [],
  subtitle: none,
  meta: none,
) = touying-slide-wrapper(self => {
  touying-slide(self: self, context {
    let ctx = _state.get()
    block(
      width: 100%,
      height: 100%,
      inset: (x: ctx.pad-x, y: 72pt),
    )[
      #stack(
        v(1fr),
        block(width: 100%)[
          #set text(
            size: ctx.hero,
            weight: 600,
            fill: ctx.ink,
            tracking: -1.4pt,
          )
          #set par(leading: 0.38em)
          #title
        ],
        v(22pt),
        if subtitle != none {
          block(width: 78%)[
            #set text(size: ctx.body, fill: ctx.muted)
            #set par(leading: 0.5em)
            #subtitle
          ]
        },
        v(1fr),
        if meta != none {
          text(size: ctx.meta, fill: ctx.faint, meta)
        },
      )
    ]
  })
})

#let section(title) = touying-slide-wrapper(self => {
  touying-slide(self: self, context {
    let ctx = _state.get()
    block(
      width: 100%,
      height: 100%,
      inset: (x: ctx.pad-x, y: 72pt),
    )[
      #align(horizon + left)[
        #block(width: 92%)[
          #set text(
            size: ctx.hero,
            weight: 600,
            fill: ctx.ink,
            tracking: -1.4pt,
          )
          #set par(leading: 0.38em)
          #title
        ]
      ]
    ]
  })
})

#let slide(title: [], body) = touying-slide-wrapper(self => {
  touying-slide(self: self, _frame[
    #_title(title)
    #v(32pt)
    #block(width: 100%)[
      #set text(size: _defaults.body)
      #body
    ]
  ])
})

#let point(body) = touying-slide-wrapper(self => {
  touying-slide(self: self, context {
    let ctx = _state.get()
    block(
      width: 100%,
      height: 100%,
      inset: (x: ctx.pad-x, y: 72pt),
    )[
      #align(horizon + left)[
        #block(width: 86%)[
          #set text(
            size: 36pt,
            weight: 500,
            fill: ctx.ink,
            tracking: -0.6pt,
          )
          #set par(leading: 0.48em)
          #body
        ]
      ]
    ]
  })
})

#let close(
  title: [Thank you.],
  meta: none,
) = touying-slide-wrapper(self => {
  touying-slide(self: self, context {
    let ctx = _state.get()
    block(
      width: 100%,
      height: 100%,
      inset: (x: ctx.pad-x, y: 72pt),
    )[
      #stack(
        v(1fr),
        block(width: 100%)[
          #set text(
            size: ctx.hero,
            weight: 600,
            fill: ctx.ink,
            tracking: -1.4pt,
          )
          #set par(leading: 0.38em)
          #title
        ],
        v(1fr),
        if meta != none {
          text(size: ctx.meta, fill: ctx.faint, meta)
        },
      )
    ]
  })
})

#let theme(
  title: none,
  link-color: _defaults.link,
  body,
) = {
  let ctx = _defaults
  ctx.title = title
  ctx.link = link-color
  show: touying-slides.with(
    config-page(
      width: 1152pt,
      height: 648pt,
      margin: 0pt,
      fill: ctx.bg,
      header: none,
      footer: none,
    ),
    config-methods(
      init: (self: none, body) => {
        set text(
          font: ctx.font,
          weight: 400,
          size: ctx.body,
          fill: ctx.ink,
        )
        set par(leading: 0.55em, spacing: 0.85em)
        set list(
          marker: text(fill: ctx.muted, size: 0.55em)[●],
          spacing: 0.72em,
          indent: 0.9em,
        )
        set enum(spacing: 0.72em, indent: 0.9em)
        show strong: set text(weight: 600)
        show heading.where(level: 2): it => pad(bottom: 0.55em, it)
        show link: set text(fill: link-color)
        show regex("https?://\\S+"): it => link(it.text)
        _state.update(_ => ctx)
        body
      },
    ),
  )
  body
}
