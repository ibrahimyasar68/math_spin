# Google Play — English store listing (copy-paste ready)

> The app's interface is **Turkish**. This listing says so plainly near the end
> so that English-speaking users are not surprised after installing. If the UI
> is localized later, delete the "A note on language" paragraph.

## App name (max 30)

```
MathSpin – Math for Kids
```

## Short description (max 80)

```
Spin the reels, solve the math, collect stars. No ads, no internet needed.
```

## Full description (max 4000)

```
MathSpin turns math practice into a slot machine. Your child taps SPIN, three
reels roll to a stop, and a fresh question appears. Answer it, watch the
confetti, and move on to the next one.

WHAT'S INSIDE

• 40 categories, 340 questions in total — a full path from first sums to
  four-digit arithmetic.
• Difficulty climbs on two axes at once. Across the four blocks of ten
  categories the numbers grow from 1 digit to 2, 3 and 4 digits; inside each
  block the operations grow from addition and subtraction to multiplication
  and, from the sixth category on, division.
• Later categories in a block have fewer questions but harder ones — 10 at the
  start, down to 5 in the tenth — so the finish line never feels far away.
• Every question comes in one of two shapes: "7 x 6 = ?" or "7 x ? = 42".
  The second kind is the one that teaches how the operations undo each other.
• Divisions always come out even, subtraction never goes below zero, and
  factors stay between 2 and 9. No traps, no negative numbers.

HOW A CHILD MOVES FORWARD

Score 80% or better and the category is passed. A birthday cake appears, one
candle for each category cleared, and the next category unlocks. Clear all 40
and the final cake arrives with ten candles, followed by the champion screen:
40 categories, 340 questions, 4 blocks.

Each full run is worth one star, and stars are kept forever — starting over
never takes one away. The tenth star finishes the game for good.

MADE FOR CHILDREN, AND FOR THEIR PARENTS

• No ads. No in-app purchases. Nothing to buy, ever.
• No accounts, no sign-in, no personal data collected.
• No internet connection required — the app does not even ask for the internet
  permission, so it works the same on a plane or in the back of a car.
• Five characters to choose from, a light and a dark theme, and sound that can
  be switched off in one tap for quiet rooms.
• Big buttons, a friendly number keypad, and text that stays readable on small
  phones.

BEST FOR

Ages 6 to 12, or any child working on addition, subtraction, multiplication and
division. Younger children can stay in the first ten categories with
single-digit numbers; older ones will find the four-digit block a real test.

A NOTE ON LANGUAGE

The interface is currently in Turkish. The math itself is universal — the
numbers, the reels and the buttons are easy to follow — but menus and messages
are Turkish for now.
```

## Char counts

Doğrulamak için:

```bash
python3 - <<'PY'
import re, pathlib
t = pathlib.Path('store/listing_en.md').read_text()
blocks = re.findall(r'```\n(.*?)\n```', t, re.S)
for name, b, lim in zip(['ad', 'kısa açıklama', 'tam açıklama'], blocks, [30, 80, 4000]):
    print('%-14s %4d / %d  %s' % (name, len(b), lim, 'OK' if len(b) <= lim else 'UZUN!'))
PY
```
