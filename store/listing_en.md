# Google Play — English store listing (copy-paste ready)

> Rewritten on 5 Sep 2026 for the puzzle version (1.1.0 / versionCode 4).
> The previous text still described 40 categories and 340 questions and did not
> mention the puzzle at all; it was never published, so nothing in Console had
> to be replaced.
>
> The app's interface is **Turkish**. This listing says so plainly at the end so
> that English-speaking users are not surprised after installing. If the UI is
> localized later, delete the "A note on language" paragraph.

Where: Play Console → Grow → Store presence → **Main store listing**, language
picker `English (en-US)`. Turkish version → [listing_tr.md](listing_tr.md).

## App name (max 30)

```
MathSpin – Math for Kids
```

## Short description (max 80)

```
Math for kids: spin the reels, solve the problem, win a puzzle piece!
```

Mirrors the Turkish short description. "Math" and "kids" carry the search
weight — neither word appears in the app name — and the three verbs describe
one full loop of the game.

### Alternatives considered

| Chars | Text | Emphasis |
|---:|---|---|
| 78 | Spin, solve, and uncover a hidden animal. No ads, no internet needed. | the two parent-facing trust signals |
| 71 | 20 levels of math for kids. Solve the questions, finish the puzzle. | volume of content |
| 66 | Ad-free math for kids: spin the reels and earn puzzle pieces. | "ad-free" first — the parent's reason to install |

## Full description (max 4000)

```
MathSpin turns math practice into a slot machine. Your child taps SPIN, three reels roll to a stop, and a question appears. They type the answer, confetti bursts, and the next question comes up.

HOW IT IS PLAYED

Each category is 5 questions long. Get 4 of the 5 right and the category is passed. Miss the mark and the same category is played again from the start — progress never goes backwards, nothing is ever lost.

A JIGSAW AT THE END OF EVERY CATEGORY

This is where the real surprise is. Every category is assigned a hidden animal painting, and the painting is cut into 10 jigsaw pieces. Each game that clears the mark opens one random piece. Below it the game asks "which animal is this?" and offers four choices. A correct guess passes the category; a wrong one keeps the child in the same category, but the pieces already opened stay open, so the picture is a little clearer next time.

There are 12 animals: horse, bear, rabbit, cat, dog, bird, elephant, lion, frog, fish, sheep and fox. All of them are hand-drawn, friendly and easy to recognize.

HOW THE DIFFICULTY GROWS

The twenty categories are split into two halves. In the first ten the numbers are single-digit (1-9), in the next ten they are two-digit (10-99). The second half sprinkles in an occasional easy question on purpose, to let the child breathe.

Inside each half the operations open up step by step: addition and subtraction at first, multiplication in the middle, division towards the end.

Questions come in two shapes: "7 x 6 = ?" or "7 x ? = 42". The second kind is the one that teaches how the operations undo each other.

The rules are child-friendly: divisions always come out even, with no remainder. Subtraction never goes below zero. Factors and divisors stay between 2 and 9, so the answers stay small enough to hold in your head.

REWARDS

Every category passed brings up a birthday cake, with one candle for each category cleared so far — the child blows them out with a finger. Finish all twenty and the final cake arrives with ten candles, followed by the champion screen and its crowned mascot.

Each full run is worth one star. Stars are kept forever; starting over never takes one away. The tenth star finishes the game for good.

FOR PARENTS

• No ads. No in-app purchases. Nothing is sold, ever.
• No accounts, no sign-in, no personal data collected.
• No internet required — the app does not even ask for the internet permission. It works the same on a plane as in the back of a car.
• Five characters to choose from, a light and a dark theme, and sound that can be switched off with one tap.
• Big buttons, a plain number keypad, and text that stays readable on small phones.

BEST FOR

Ages 6 to 12, or any child working on addition, subtraction, multiplication and division. Younger children can stay in the first ten categories with single-digit numbers; older ones will find the two-digit half a real test.

A NOTE ON LANGUAGE

The interface is currently in Turkish. The math itself is universal — the numbers, the reels and the buttons are easy to follow — but menus and messages are Turkish for now.
```

## Char counts

To verify:

```bash
python3 - <<'PY'
import re, pathlib
t = pathlib.Path('store/listing_en.md').read_text()
blocks = re.findall(r'```\n(.*?)\n```', t, re.S)
for name, b, lim in zip(['name', 'short desc', 'full desc'], blocks, [30, 80, 4000]):
    print('%-12s %4d / %d  %s' % (name, len(b), lim, 'OK' if len(b) <= lim else 'TOO LONG!'))
PY
```
