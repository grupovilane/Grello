<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->
- The imported GS Quadros app is plain HTML/JS served from public/ (app.js, cloud.js, modelos.js, config.js, gs-styles.css, assets/) and mounted by src/routes/index.tsx; edit those files rather than rewriting in React, to keep the original behavior intact.
- public/cloud.js uses the app's backend client and managed Google sign-in exposed by src/routes/index.tsx on window (__gsSupabase, __gsGoogle); never create a second client or call raw Google OAuth there.
- Feedback is stored separately from board backups; enforce ownership and administrator access with database policies, and reuse the existing cloud channel for report notifications.
