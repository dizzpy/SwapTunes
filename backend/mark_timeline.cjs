const fs = require('fs');
const file = './Project Docs/09-sprint-timeline.md';
let content = fs.readFileSync(file, 'utf8');

const completedTasks = [
  "Init Node.js + Express project",
  "Set up global error handler",
  "Init Git repo",
  "`requireAuth` middleware",
  "`POST /auth/profile/setup`",
  "`GET /users/me`",
  "`GET /users/:username`",
  "`POST + DELETE /users/:id/follow`",
  "`POST /posts`",
  "`GET /posts/feed`",
  "`POST + DELETE /posts/:id/like`",
  "`GET + POST /posts/:id/comments`",
  "`POST /posts/:id/report`",
  "`POST /posts/:id/hide`",
  "`notifications.service`",
  "`POST /auth/spotify/connect`",
  "`spotify.service`",
  "`requireSpotify` middleware",
  "`GET /playlists/spotify/available`",
  "`POST /playlists/import`",
  "`requireCreator` middleware",
  "`POST /creator/setup`",
  "Update `GET /users/me` + `GET /users/:username`",
  "`POST /collabs`",
  "`GET /collabs`",
  "`GET /collabs/:id`",
  "`PATCH /collabs/:id`",
  "`DELETE /collabs/:id`",
  "`POST /conversations`",
  "`GET /conversations`",
  "`POST /conversations/:id/messages`",
  "`GET /conversations/:id/messages`",
  "Wire message notification",
  "`GET /discover/playlists`",
  "`GET /discover/suggested-users`",
  "`GET /discover/search` (users)",
  "`GET /discover/search` (playlists)",
  "`GET /discover/search` (creators)",
  "`GET /discover/search?type=all`",
  "`GET /notifications`",
  "`PATCH /notifications/read-all`",
  "Wire follow notification",
  "Wire collab notification"
];

let lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('- [ ]')) {
    for (const task of completedTasks) {
      if (lines[i].includes(task)) {
        lines[i] = lines[i].replace('- [ ]', '- [x]');
        break;
      }
    }
  }
}

fs.writeFileSync(file, lines.join('\n'), 'utf8');
console.log('Timeline updated successfully!');
