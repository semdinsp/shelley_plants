# Admin Guide: Editing Plants and Using Claude Desktop

Hi Shelley,

This guide covers two things:

1. **Editing plants on the website** — the normal way, through the admin pages.
2. **Creating an MCP token** — a special key that lets Claude Desktop read and edit plants for you, if you want to try that.

If you only ever use the website to edit plants, you can skip the MCP sections entirely — everything still works exactly the same without one.

---

## Part 1: Editing plants on the website

### Logging in

Go to the site and log in with your email — you'll get a magic link by email instead of a password. Once logged in as an admin, you'll see extra menu items: **Admin** and **Settings**, and admin-only buttons on plant pages.

### Editing an existing plant

1. Click **Species List** in the top menu.
2. Find the plant you want to change (use the category filter buttons — All / Wildflower / Grass / Shrub / Tree — to narrow it down).
3. Click the **eye icon** next to the plant, or click anywhere on its row, to open the plant's page.
4. Click **Edit plant** near the top.
5. Change whatever fields need updating.
6. Click **Save Plant** at the bottom.

Your changes appear immediately — no need to wait or refresh.

### Adding a new plant

1. Click **Species List**, then click **New Plant** near the top.
2. Fill in the fields. Common name, Latin name, flower color, bloom time, height, light requirements, moisture, and plant type are all required — the form will tell you if something's missing when you try to save.
3. Click **Save Plant**.

### Deleting a plant

From the **Species List** table, click **Delete** on the plant's row. You'll be asked to confirm — this can't be undone, so make sure it's the right plant first.

### A note on the structured fields

A few fields — **Category**, **Sun level**, **Moisture level**, and **Height/spread in cm** — are separate from the older free-text fields (like "Light requirements" or "Height"). The structured fields power the **Garden Planner** tool on the site, which matches plants to a customer's space by sun, moisture, height, and layout. If you leave them blank, the plant just won't show up as a match in the Garden Planner — it'll still appear everywhere else on the site as normal.

---

## Part 2: Creating an MCP token for Claude Desktop

An MCP token is a password-like key, created on the **Settings** page, that lets an AI assistant like Claude Desktop connect to the site and act on your behalf — reading the plant catalog, and optionally editing it too. You only need to do this once per device you want to use with Claude.

### Creating the token

1. Log in to the site as an admin.
2. Click **Settings** in the top menu.
3. Scroll to **MCP tokens**. (This section only appears for admin accounts.)
4. Under **Token name**, give it a name you'll recognize later, like `claude-desktop`.
5. Choose what the token can do:
   - **Read** — lets Claude look up plants (always check this).
   - **Write** — lets Claude create, edit, or delete plants. Only check this if you actually want Claude to be able to make changes for you.
6. Click **Create token**.

The token is shown once and automatically copied to your clipboard — **save it somewhere safe right away**, like a password manager or a private note. If you lose it, you'll need to create a new one; there's no way to view an old token again.

### Revoking a token

If a token is no longer needed, or you think it may have leaked, go back to **Settings → MCP tokens** and click **Revoke** next to it. This takes effect immediately — anything using that token (including Claude Desktop) will stop working right away.

### Connecting Claude Desktop

Once you have a token, ask whoever manages the site's Claude Desktop setup to add an entry like this to `claude_desktop_config.json`, using your token:

```json
"biosphere-plants": {
  "command": "npx",
  "args": [
    "-y",
    "mcp-remote@latest",
    "https://YOUR-SITE-URL-HERE/mcp",
    "--header",
    "Authorization: Bearer ${BIOSPHERE_MCP_TOKEN}"
  ],
  "env": {
    "BIOSPHERE_MCP_TOKEN": "paste-your-token-here"
  }
}
```

Replace `YOUR-SITE-URL-HERE` with the site's real address (for local testing, this is usually `localhost:4070`). Restart Claude Desktop afterward for it to pick up the new connection.

---

## Part 3: Using Claude Desktop to edit plants with a write-scoped token

If your token has **Write** access checked, you can ask Claude Desktop to make changes to the plant catalog directly, in plain English, instead of using the website's edit forms.

**Some things you can ask it to do:**

- *"Add a new plant called Wild Bergamot — Latin name Monarda fistulosa, perennial, full sun, average moisture, deer resistant, blooms July to August."*
- *"Update the Black-eyed Susan's moisture level to dry."*
- *"List all the Wildflower plants that are full sun and dry."*
- *"Delete the test plant I added yesterday called 'Test Plant 123'."*

Claude will make the change and tell you what happened — including if something went wrong (for example, if a required field like the Latin name is missing, or if the name is already used by another plant).

**A few things worth knowing:**

- Changes made this way go live on the website immediately, exactly the same as if you'd used the edit form yourself.
- If your token only has **Read** access checked (no Write), Claude can look up and describe plants, but any request to add, change, or delete one will be turned down — you'll see a message saying the token doesn't have write access. In that case, go back to Settings and create a new token with Write checked (revoking the old one if you no longer need it).
- The MCP tokens section only appears in Settings for admin accounts, and a token only works for making changes if it belongs to an admin — same rule as editing on the website.
- If you ever want to stop Claude from being able to make changes, revoke the token in **Settings** — this is instant and doesn't require you to do anything on the Claude Desktop side.
