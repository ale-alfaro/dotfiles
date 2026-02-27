#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["PyGObject"]
# ///
import argparse
import datetime as dt
import os
import re
import subprocess
from collections.abc import Generator, Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

try:
    import gi

    gi.require_version("Gio", "2.0")
    from gi.repository import Gio


except ImportError or ValueError as exc:
    print("Error: Dependencies not met.", exc)
    SystemExit(1)


def notify(title: str, message: str, urgency: str):
    if not Gio:
        return
    noti: Gio.Notification = Gio.Notification.new(title)
    noti.set_body(message)
    noti.set_priority(urgency)
    Gio.Notification.send_notification("reminders", noti)


OBSIDIAN_HOME: str = os.environ.get("OBSIDIAN_HOME", "~/Documents/Obsidian")

BASE = Path(OBSIDIAN_HOME).expanduser()
FILES = [
    Path(BASE, "Sibel-Work", "TODO.md"),
    Path(BASE, "Personal-Geek", "TODO.md"),
]

DATE_PATTERNS = {
    "due": re.compile(r"📅\s*(\d{4}-\d{2}-\d{2})"),
    "scheduled": re.compile(r"⏳\s*(\d{4}-\d{2}-\d{2})"),
    "start": re.compile(r"🛫\s*(\d{4}-\d{2}-\d{2})"),
}

PRIORITY_MAP = {
    "⏬": "lowest",
    "🔽": "low",
    "🔼": "medium",
    "⏫": "high",
    "🔺": "highest",
}

RECURRENCE_EVERY_DAY = re.compile(r"🔁\s*every\s+day", re.IGNORECASE)
RECURRENCE_WEEKDAY = re.compile(
    r"🔁\s*every\s+week\s+on\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)",
    re.IGNORECASE,
)

TASK_LINE = re.compile(r"^\s*-\s*\[(?P<status>[^\]]*)\]\s*(?P<body>.+)$")

WEEKDAYS = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
}


@dataclass
class Task:
    source: Path
    body: str
    priority: str
    due: dt.date | None
    scheduled: dt.date | None
    start: dt.date | None
    recurrence: str | None

    def is_active_on(self, day: dt.date) -> bool:
        if self.due == day or self.scheduled == day or self.start == day:
            return True
        if self.start and self.start < day and (self.due is None or self.due >= day):
            return True
        if self.recurrence == "every_day":
            return True
        if self.recurrence and self.recurrence.startswith("weekly_"):
            weekday = int(self.recurrence.split("_", 1)[1])
            return day.weekday() == weekday
        return False


def parse_date(pattern: re.Pattern[str], text: str) -> dt.date | None:
    m = pattern.search(text)
    if not m:
        return None
    try:
        return dt.date.fromisoformat(m.group(1))
    except ValueError:
        return None


def parse_priority(text: str) -> str:
    for emoji, name in PRIORITY_MAP.items():
        if emoji in text:
            return name
    return "normal"


def parse_recurrence(text: str) -> str | None:
    if RECURRENCE_EVERY_DAY.search(text):
        return "every_day"
    m = RECURRENCE_WEEKDAY.search(text)
    if m:
        weekday = WEEKDAYS[m.group(1).lower()]
        return f"weekly_{weekday}"
    return None


def iter_tasks(path: Path) -> Generator[Task | None]:
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            m = TASK_LINE.match(line)
            if not m:
                continue
            status = m.group("status").strip().lower()
            if status in {"x", "-"}:
                continue
            body = m.group("body").strip()
            task = Task(
                source=path,
                body=body,
                priority=parse_priority(body),
                due=parse_date(DATE_PATTERNS["due"], body),
                scheduled=parse_date(DATE_PATTERNS["scheduled"], body),
                start=parse_date(DATE_PATTERNS["start"], body),
                recurrence=parse_recurrence(body),
            )
            yield task


#
# def notify(title: str, body: str, urgency: str = "normal") -> None:
#     if not body.strip():
#         return
#     try:
#         subprocess.run(
#             [
#                 "notify-send",
#                 "-a",
#                 "todo-reminder",
#                 "-u",
#                 urgency,
#                 "-t",
#                 "10000",
#                 title,
#                 body,
#             ],
#             check=True,
#         )
#     except subprocess.CalledProcessError:
#         print("Failed to notify")
#         raise


def format_tasks(tasks: Iterable[Task]) -> str:
    lines = [f"{t.source} | {t.body}" for t in tasks]
    return "\n".join(lines)


type MODES = Literal["morning", "noon", "evening"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode", choices=["morning", "noon", "evening"], default="noon"
    )
    parser.add_argument("--todos", type=Path, required=False)
    args = parser.parse_args()

    today = dt.date.today()
    if (todos := args.todos) and todos.is_file():
        todo_files = [todos]
    else:
        todo_files = [file for file in FILES if file.is_file()]
    tasks = [t for f in todo_files for t in iter_tasks(f)]
    active = [t for t in tasks if t and t.is_active_on(today)]
    mode: MODES = args.mode or "noon"
    print(f"TASKS {tasks}. ACTIVE {active}. MODE {mode}")
    if mode == "morning":
        body = format_tasks(active)
        notify("Today: Active tasks", body, urgency="normal")
    elif mode == "noon":
        high = [t for t in active if t.priority in {"high", "highest"}]
        body = format_tasks(high)
        notify("Today: High-priority tasks", body, urgency="critical")
    elif mode == "evening":
        summary = format_tasks(active)
        prompt = "Check-in: update reminders in TODO.md"
        body = f"{summary}\n\n{prompt}" if summary else prompt
        notify("Today: Summary + check-in", body, urgency="normal")
    else:
        raise ValueError

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
