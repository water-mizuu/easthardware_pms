## May 19, 2025 || 9:44PM

I have started work on the server thing. There are still many problems ahead.

1. I should let the user go back on their decisions on setting up.
2. I should think of a way to reroute the database to use the backend server.
3. I should think of a way to connect each DAO to a proxy instead of a database object.
  - Proxy Database. (?) How would this work?
  - I am thinking for reactivity to non-self database changes, each DAO should basically
    have a stale/updated state. If the DAO becomes stale, they ping the server again for
    the updated information.
4. Each BLOC should have an OnDatabaseUpdate event, which updates the UI. How can this be 
  done in a clean fashion?