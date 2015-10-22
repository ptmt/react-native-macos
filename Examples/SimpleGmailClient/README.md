Stateless Gmail Client using REST API.

- No WebViews yet, so there is no fancy oAuth login process;
- Cmd-V doesn't work, copy manually using a context menu;
- Read-Only;
- RefreshToken is not used at all, you've got *3600 seconds* per session;
- No Redux;
- No batching requests https://developers.google.com/gmail/api/guides/batch;
- A lot of UI TODOS;
