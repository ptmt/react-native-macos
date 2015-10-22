Gmail Client via Google REST API. 

- Dumb;
- Stateless;
- No WebViews for now, so there is no fancy oAuth login process;
- Cmd-V doesn't work yet, authorization requires coping the code manually using a context menu;
- Read-Only;
- RefreshToken is not used at all, so you've got *3600 seconds* per session;
- No Redux;
- No batching requests https://developers.google.com/gmail/api/guides/batch;
- A lot of UI TODOS;

<img width="931" alt="screenshot 2015-10-22 16 57 42" src="https://cloud.githubusercontent.com/assets/1004115/10663590/f21b0e40-78d5-11e5-8a86-b55538fb061d.png">
<img width="959" alt="screenshot 2015-10-22 16 56 43" src="https://cloud.githubusercontent.com/assets/1004115/10663594/f81a2934-78d5-11e5-9f7a-f6bb312763f4.png">

