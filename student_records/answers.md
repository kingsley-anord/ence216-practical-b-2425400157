# Why does `_refresh()` still need `setState()` even though the database already has the new data?

Writing to SQLite (insert/update/delete) only changes the bytes on disk inside
`student_records.db`. Flutter's widget tree is completely unaware that the
file changed - the framework does not watch the database, it only rebuilds a
widget when it is told a widget's *State* has changed.

`_refresh()` re-queries the database and stores the result in the in-memory
list `_students`, which lives inside `_StudentListPageState`. Just assigning
`_students = data` on its own would update the variable, but the `build()`
method would never be called again, so the screen would keep showing the old
list until some unrelated rebuild happened to occur.

Calling `setState()` is what tells the Flutter framework "this State object
changed, please call build() again." Only then does the `ListView.builder`
re-read `_students` and redraw the rows on screen.

So the two steps are separate on purpose:
1. Persist the change (SQLite) - so it survives an app restart.
2. Trigger a UI refresh (setState) - so the *current* screen reflects it
   immediately, without needing a restart.

Skipping step 2 is exactly the "List never updates" bug described in the
practical's Common Errors section.
