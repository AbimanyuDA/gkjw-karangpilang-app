const ID_PATTERN = /(?:youtu\.be\/|\/v\/|embed\/|live\/|shorts\/|watch\?v=|&v=)([A-Za-z0-9_-]{11})/

/** ID video (11 karakter) dari link YouTube apa pun, atau ID mentah. */
export function extractVideoId(input: string): string | null {
  const s = input.trim()
  if (/^[A-Za-z0-9_-]{11}$/.test(s)) return s
  return s.match(ID_PATTERN)?.[1] ?? null
}
