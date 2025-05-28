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

## May 26, 2025 || 10:56AM -- @water-mizuu

I just did basic integration with the backend database, and theoretically LAN connectivity
should just work. Addressing the previous points:
1. Successful, the user can keep going back until they are prompted to choose between
  client and server. Now, there are still some testing to do, but basic functionality
  is complete
2. --
3. The proxy database approach works. Basically works as a manual reflection system.
  Each invocation is encoded as a json, which is sent to the webSocket / isolate,
  which processes each request atomically.
  - For atomicity, each request is enqueued on a database queue. Race conditions be damned.
    (Testing is needed.)
  - For reactivity, each BLOC object is hooked into the Dependency Injector, which then add
    the "init" event on each one as the database changes. This makes all hosted blocs refresh,
    which is not optimal.
4. I used the DI.

Now, onto the main issues. I added FocusScopeWidgets, but it seems that they do not interact with
one another, needing mouse clicks on a what is supposed to be a tab-driven workflow. I need
to look into this. Furthermore, I need to change the units in the creation / edit windows, so
there's that