// Example slides for the theme. Add a slide here when a new feature lands.
#import "theme.typ": *

#show: theme.with(
  title: [Theme demo],
)

#cover(
  title: [A quieter theme.],
  subtitle: [The space and type of a plain document, without the repository chrome.],
  meta: [31 October 2026],
)

#section[Layout]

#slide(title: [One idea, then the next])[
  A slide is a title, a short rule, and a few lines.

  - Keep the title short enough to say aloud.
  - Use a list or a paragraph, not a pile of both.
  - Secondary text stays gray, so the title does the work.
]

#slide(title: [What the page is for])[
  #columns(
    [
      #eyebrow[On the slide]
      White field, large type, and one dark rule. The name of the talk and a page number are the only running text.
    ],
    [
      #eyebrow[Left off]
      Badges, monospace labels, terminal frames, and status colors. They make a talk look like a dashboard.
    ],
  )
]

#point[A slide should read like a sentence, \ not a status page.]

#close(
  title: [Thank you.],
  meta: [Questions],
)
